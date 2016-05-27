# This file is part of the OpenWISP Geographic Monitoring
#
# Copyright (C) 2012 OpenWISP.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

require 'thread'
require "net/ping"
include Net

class MonitoringWorker < BackgrounDRb::MetaWorker
  set_worker_name :monitoring_worker

  MAX_THREADS = CONFIG['max_threads']
  PING_TIMEOUT = CONFIG['ping_timeout']
  MAX_PINGS = CONFIG['max_pings']

  @@monitoring_semaphore = Mutex.new
  @@users_count_semaphore = Mutex.new

  def create(args = nil)
    # this method is called, when worker is loaded for the first time
  end

  def access_points_monitoring
    threads = []
    access_points = AccessPoint.with_properties_and_group("access_points.*, property_sets.reachable, property_sets.public, property_sets.site_description,
      property_sets.category, property_sets.group_id, property_sets.notes, groups.monitor AS group_monitor")

    started = Time.now
    access_points.each do |ap|
      begin
        # if access point is in a group which is not being monitored
        # for some reason when joining active records return a string instead of a boolean
        if ap.group_monitor == "0" or ap.group_monitor == false
          next
        end

        # wait until there is a "slot" for a new thread
        while threads.length >= MAX_THREADS
          threads.delete_if { |th| th.alive? ? false : th.join(1) }
          sleep(0.2)
        end

        # spawn a new thread
        threads.push(Thread.new do
          begin
            reachable = nil
            # do a maximum number of pings as indicated in MAX_PINGS
            MAX_PINGS.times do
              # initialize
              pt = Net::Ping::External.new(ap.ip, nil, PING_TIMEOUT)
              # perform ping
              reachable = pt.ping?
              # if ping is successful exit loop, otherwise keep trying until MAX_PINGS
              if reachable
                break
              end
            end
            act = ap.activities.build(:status => reachable) if ap.known? || (ap.unknown? && reachable)
          rescue
            act = ap.activities.build(:status => false) if ap.known?
          end

          if act
            # avoid race conditions with the consolidate_access_points_monitoring() function
            @@monitoring_semaphore.synchronize {
              # save activity
              act.save!
              # if AP reachable status changed
              if act.status != ap.reachable?
                # change AP status
                act.status ? ap.reachable! : ap.unreachable!
              end
            }
          end
        end)
      rescue Exception => e
        puts "[#{Time.now}] Problem while pinging ap '#{ap.hostname}'"
        puts "[#{Time.now}] #{e.message}"
        puts "[#{Time.now}] #{e.backtrace.inspect}"
        if CONFIG['exception_notifier_enabled']
          ExceptionNotifier::Notifier.background_exception_notification(e).deliver
        end
        if CONFIG['sentry_enabled']
          Raven.capture_exception(e)
        end
        next
      end
    end

    begin
      # collect remaining threads that are finished theirs job
      while threads.length > 0
        threads.delete_if { |th| th.alive? ? false : th.join() }
        sleep(0.2)
      end
    rescue Exception => e
      puts "[#{Time.now}] Got exception while cleaning threads"
      puts "[#{Time.now}] #{e.message}"
      puts "[#{Time.now}] #{e.backtrace.inspect}"
      if CONFIG['exception_notifier_enabled']
        ExceptionNotifier::Notifier.background_exception_notification(e).deliver
      end
      if CONFIG['sentry_enabled']
        Raven.capture_exception(e)
      end
    end
    execution_time = Time.now - started
    puts "[#{Time.now}] access_points_monitoring completed in #{execution_time}"

    # update group statistics
    Group.update_all_counts()
  end

  def consolidate_access_points_monitoring
    # calculate average of activities
    access_points = AccessPoint.with_properties_and_group("access_points.*, property_sets.reachable, property_sets.public, property_sets.site_description,
      property_sets.category, property_sets.group_id, property_sets.notes, groups.monitor AS group_monitor")

    access_points.each do |ap|
      # if access point is in a group which is not being monitored
      # for some reason when joining active records return a string instead of a boolean
      if ap.group_monitor == "0" or ap.group_monitor == false
        next
      end

      begin
        # avoid race conditions with the access_points_monitoring() function
        @@monitoring_semaphore.synchronize {
          if ap.activities.count > 0
            last_history_time = ap.activity_histories.last.try(:last_time)

            if last_history_time
              first_time = ap.activities.where('created_at > ?', last_history_time).first.created_at.change(:min => 0, :sec => 0)
            else
              first_time = ap.activities.first.created_at.change(:min => 0, :sec => 0)
            end
            last_time = ap.activities.last.created_at.change(:min => 0, :sec => 0)

            # calculate the number of status changes
            status_changes = ap.get_status_changes_between_dates(first_time..last_time)

            avg = ap.activities.where(:created_at => first_time..last_time).average(:status)
            if avg
              history = ap.activity_histories.build(
                :status => avg.to_f,
                :start_time => first_time,
                :last_time => last_time,
                :num_change_status => status_changes
              )
              history.save!
            end

            ap.activities.not_recent.destroy_all
          end
        }
      rescue Exception => e
        puts "[#{Time.now}] Problem in consolidate_access_points_monitoring() for access point '#{ap.hostname}': #{e}"
        puts "[#{Time.now}] #{e.message}"
        puts "[#{Time.now}] #{e.backtrace.inspect}"
        if CONFIG['exception_notifier_enabled']
          ExceptionNotifier::Notifier.background_exception_notification(e).deliver
        end
        if CONFIG['sentry_enabled']
          Raven.capture_exception(e)
        end
        next
      end
    end
  end

  def associated_user_counts_monitoring
    threads = []

    Wisp.all.each do |wisp|

      # spawn a new thread if there is a "slot" for it. Otherwise, wait for an empty slot
      while threads.length >= MAX_THREADS
        threads.delete_if { |th| th.alive? ? false : th.join() }
        sleep(0.2)
      end

      if wisp.owmw_enabled?
        threads.push(Thread.new do
          begin
            aps_with_users = []
            AssociatedUser.active_resource_from(wisp.owmw_url, wisp.owmw_username, wisp.owmw_password)

            AssociatedUser.all.group_by(&:access_point_id).each do |ap_id, users|
              begin
                # avoid race conditions with the consolidate_associated_user_counts_monitoring() function
                @@users_count_semaphore.synchronize {
                  AssociatedUserCount.create!(:count => users.count, :access_point_id => ap_id)
                }
                aps_with_users << ap_id
              rescue Exception => e
                puts "[#{Time.now}] Problem in associated_user_counts_monitoring() for wisp '#{wisp.name}', access point id '#{ap_id}': #{e}"
                puts "[#{Time.now}] #{e.message}"
                puts "[#{Time.now}] #{e.backtrace.inspect}"
                if CONFIG['exception_notifier_enabled']
                  ExceptionNotifier::Notifier.background_exception_notification(e).deliver
                end
                if CONFIG['sentry_enabled']
                  Raven.capture_exception(e)
                end
                next
              end
            end

            if aps_with_users.empty?
              aps_without_users = wisp.access_points
            else
              aps_without_users = wisp.access_points.where(["id NOT IN (?)", aps_with_users])
            end

            aps_without_users.each do |ap|
              begin
                # avoid race conditions with the consolidate_associated_user_counts_monitoring() function
                @@users_count_semaphore.synchronize {
                  AssociatedUserCount.create!(:count => 0, :access_point_id => ap.id)
                }
              rescue Exception => e
                puts "[#{Time.now}] Problem in associated_user_counts_monitoring() for wisp '#{wisp.name}', access point '#{ap.hostname}': #{e}"
                puts "[#{Time.now}] #{e.message}"
                puts "[#{Time.now}] #{e.backtrace.inspect}"
                if CONFIG['exception_notifier_enabled']
                  ExceptionNotifier::Notifier.background_exception_notification(e).deliver
                end
                if CONFIG['sentry_enabled']
                  Raven.capture_exception(e)
                end
                next
              end
            end
          rescue Exception => e
            puts "[#{Time.now}] Problem in associated_user_counts_monitoring() for wisp '#{wisp.name}': #{e}"
            puts "[#{Time.now}] #{e.message}"
            puts "[#{Time.now}] #{e.backtrace.inspect}"
            if CONFIG['exception_notifier_enabled']
              ExceptionNotifier::Notifier.background_exception_notification(e).deliver
            end
            if CONFIG['sentry_enabled']
              Raven.capture_exception(e)
            end
          end
        end)
      end

    end

    # collect remaining threads that are finished theirs job
    while threads.length > 0
      threads.delete_if { |th| th.alive? ? false : th.join() }
      sleep(0.2)
    end
  end

  def consolidate_associated_user_counts_monitoring
    Wisp.all.each do |wisp|
      begin
        if wisp.owmw_enabled?
          AssociatedUser.active_resource_from(wisp.owmw_url, wisp.owmw_username, wisp.owmw_password)

          wisp.access_points.each do |ap|
            begin
              # avoid race conditions with the associated_user_counts_monitoring() function
              @@users_count_semaphore.synchronize {
                if ap.associated_user_counts.count > 0
                  last_history_time = ap.associated_user_count_histories.last.try(:last_time)

                  if last_history_time
                    first_time = ap.associated_user_counts.where('created_at > ?', last_history_time).first.created_at.change(:min => 0, :sec => 0)
                  else
                    first_time = ap.associated_user_counts.first.created_at.change(:min => 0, :sec => 0)
                  end
                  last_time = ap.associated_user_counts.last.created_at.change(:min => 0, :sec => 0)

                  max = ap.associated_user_counts.where(:created_at => first_time..last_time).maximum(:count)
                  if max
                    history = ap.associated_user_count_histories.build(:count => max, :start_time => first_time, :last_time => last_time)
                    history.save!
                  end

                  ap.associated_user_counts.not_recent.destroy_all
                end
              }
            rescue Exception => e
              puts "[#{Time.now}] Problem in consolidate_associated_user_counts_monitoring() for wisp '#{wisp.name}', access point '#{ap.hostname}': #{e}"
              puts "[#{Time.now}] #{e.message}"
              puts "[#{Time.now}] #{e.backtrace.inspect}"
              if CONFIG['exception_notifier_enabled']
                ExceptionNotifier::Notifier.background_exception_notification(e).deliver
              end
              if CONFIG['sentry_enabled']
                Raven.capture_exception(e)
              end
              next
            end
          end
        end
      rescue Exception => e
        puts "[#{Time.now}] Problem in consolidate_associated_user_counts_monitoring() for wisp '#{wisp.name}': #{e}"
        puts "[#{Time.now}] #{e.message}"
        puts "[#{Time.now}] #{e.backtrace.inspect}"
        if CONFIG['exception_notifier_enabled']
          ExceptionNotifier::Notifier.background_exception_notification(e).deliver
        end
        if CONFIG['sentry_enabled']
          Raven.capture_exception(e)
        end
        next
      end
    end
  end

  def housekeeping
    begin
      time = CONFIG['housekeeping_interval'].months.to_i.ago
      AssociatedUserCountHistory.destroy_all(["created_at < ?", time])
      # delete old alerts
      Alert.destroy_all(["created_at < ?", time])
      # build missing property sets
      AccessPoint.build_all_properties()
      # delete orphan property sets
      PropertySet.destroy_orphans()
    rescue Exception => e
      puts "Problem in housekeeping"
      puts "[#{Time.now}] #{e.message}"
      puts "[#{Time.now}] #{e.backtrace.inspect}"
      if CONFIG['exception_notifier_enabled']
        ExceptionNotifier::Notifier.background_exception_notification(e).deliver
      end
      if CONFIG['sentry_enabled']
        Raven.capture_exception(e)
      end
    end
  end

  def clean_activityhistory
    begin
      time = CONFIG['housekeeping_interval'].months.to_i.ago
      ActivityHistory.destroy_all(["created_at < ?", time])
    rescue Exception => e
      puts "Problem in clean_activityhistory"
      puts "[#{Time.now}] #{e.message}"
      puts "[#{Time.now}] #{e.backtrace.inspect}"
      if CONFIG['exception_notifier_enabled']
        ExceptionNotifier::Notifier.background_exception_notification(e).deliver
      end
      if CONFIG['sentry_enabled']
        Raven.capture_exception(e)
      end
    end
  end

  def send_alerts
    begin
      Alert.send_all
    rescue Exception => e
      puts "Problem in send_alerts"
      puts "[#{Time.now}] #{e.message}"
      puts "[#{Time.now}] #{e.backtrace.inspect}"
      if CONFIG['exception_notifier_enabled']
        ExceptionNotifier::Notifier.background_exception_notification(e).deliver
      end
      if CONFIG['sentry_enabled']
        Raven.capture_exception(e)
      end
    end
  end
end
