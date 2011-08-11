require 'thread'
require "net/ping"
include Net

class MonitoringWorker < BackgrounDRb::MetaWorker
  set_worker_name :monitoring_worker

  MAX_THREADS = 10
  PING_TIMEOUT = 5

  @@semaphore = Mutex.new

  def create(args = nil)
    # this method is called, when worker is loaded for the first time

  end

  def access_points_monitoring
    threads = []
    AccessPoint.all.each do |ap|

      while threads.length >= MAX_THREADS
        threads.delete_if do |th|
          if !th.alive?
            th.join()
          else
            false
          end
        end
        sleep(0.2)
      end

      threads.push(Thread.new do
        begin
          pt = Net::Ping::External.new(ap.ip, nil, PING_TIMEOUT)
          reachable = pt.ping?
          act = ap.activities.build( :status => reachable ) if ap.known? || (ap.unknown? && reachable)
        rescue
          act = ap.activities.build( :status => false ) if ap.known?
        end
        if act
          @@semaphore.synchronize {
            act.save!
            act.status ? ap.reachable! : ap.unreachable!
          }
        end
      end)

    end

    while threads.length > 0
      threads.delete_if do |th|
        if !th.alive?
          th.join()
        else
          false
        end
      end
      sleep(0.2)
    end

  end

  def consolidate_access_points_monitoring
    AccessPoint.all.each do |ap|
      @@semaphore.synchronize {
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
    end
  end

  def associated_user_counts_monitoring
    Wisp.all.each do |wisp|
      if wisp.owmw_enabled?
        aps_with_users = []
        AssociatedUser.active_resource_from(wisp.owmw_url, wisp.owmw_username, wisp.owmw_password)

        AssociatedUser.all.group_by(&:access_point_id).each do |ap_id, users|
          AssociatedUserCount.create!(:count => users.count, :access_point_id => ap_id)
          aps_with_users << ap_id
        end

        wisp.access_points.where(["id NOT IN (?)", aps_with_users]).each do |ap|
          AssociatedUserCount.create!(:count => 0, :access_point_id => ap.id)
        end
      end
    end
  end

  def consolidate_associated_user_counts_monitoring
    Wisp.all.each do |wisp|
      if wisp.owmw_enabled?
        AssociatedUser.active_resource_from(wisp.owmw_url, wisp.owmw_username, wisp.owmw_password)

        wisp.access_points.each do |ap|
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
        end
      end
    end
  end

  def housekeeping
    time = 6.months.to_i.ago
    ActivityHistory.destroy_all(["created_at < ?", time])
    AssociatedUserCountHistory.destroy_all(["created_at < ?", time])
  end

end
