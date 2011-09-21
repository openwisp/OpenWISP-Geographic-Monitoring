# This file is part of the OpenWISP Geographic Monitoring
#
# Copyright (C) 2010 CASPUR (wifi@caspur.it)
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

  MAX_THREADS = 10
  PING_TIMEOUT = 5

  @@monitoring_semaphore = Mutex.new
  @@users_count_semaphore = Mutex.new

  def create(args = nil)
    # this method is called, when worker is loaded for the first time

  end

  def access_points_monitoring
    threads = []
    AccessPoint.all.each do |ap|

      # spawn a new thread if there is a "slot" for it. Otherwise, wait for an empty slot
      while threads.length >= MAX_THREADS
        threads.delete_if { |th| th.alive? ? false : th.join() }
        sleep(0.2)
      end

      threads.push(Thread.new do
        begin
          pt = Net::Ping::External.new(ap.ip, nil, PING_TIMEOUT)
          reachable = pt.ping?
          act = ap.activities.build(:status => reachable) if ap.known? || (ap.unknown? && reachable)
        rescue
          act = ap.activities.build(:status => false) if ap.known?
        end
        if act
          # avoid race conditions with the consolidate_access_points_monitoring() function
          @@monitoring_semaphore.synchronize {
            act.save!
            act.status ? ap.reachable! : ap.unreachable!
          }
        end
      end)

    end

    # collect remaining threads that are finished theirs job
    while threads.length >= MAX_THREADS
      threads.delete_if { |th| th.alive? ? false : th.join() }
      sleep(0.2)
    end

  end

  def consolidate_access_points_monitoring
    AccessPoint.all.each do |ap|
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

            avg = ap.activities.where(:created_at => first_time..last_time).average(:status)
            if avg
              history = ap.activity_histories.build(:status => avg.to_f, :start_time => first_time, :last_time => last_time)
              history.save!
            end

            ap.activities.not_recent.destroy_all
          end
        }
      rescue Exception => e
        puts "[#{Time.now}] Problem in consolidate_access_points_monitoring() for access point '#{ap.hostname}': #{e}"
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
                next
              end
            end
          rescue Exception => e
            puts "[#{Time.now}] Problem in associated_user_counts_monitoring() for wisp '#{wisp.name}': #{e}"
          end
        end)
      end

    end

    # collect remaining threads that are finished theirs job
    while threads.length >= MAX_THREADS
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
              next
            end
          end
        end
      rescue Exception => e
        puts "[#{Time.now}] Problem in consolidate_associated_user_counts_monitoring() for wisp '#{wisp.name}': #{e}"
        next
      end
    end
  end

  def housekeeping
    time = 6.months.to_i.ago
    ActivityHistory.destroy_all(["created_at < ?", time])
    AssociatedUserCountHistory.destroy_all(["created_at < ?", time])
  end

end
