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
          first_time = ap.activities.first(:order => "created_at").created_at.change(:min => 0, :sec => 0)
          last_time = ap.activities.first(:order => "created_at DESC").created_at.change(:min => 0, :sec => 0)
          avg = ap.activities.average(:status, :conditions => ["created_at < ?", last_time]).to_f
          ah = ap.activity_histories.build(:status => avg, :start_time => first_time, :last_time => last_time)
          ah.save!
          Activity.destroy_all(["access_point_id = ? AND created_at < ?", ap.id, last_time])
        end
      }
    end
  end

  def associated_user_counts_monitoring
    Wisp.all.each do |wisp|
      if wisp.owmw_enabled?
        AssociatedUser.all.group_by(&:access_point_id).each do |ap_id, users|
          AssociatedUserCount.create!(:count => users.count, :access_point_id => ap_id)
        end
      end
    end
  end

  def consolidate_associated_user_counts_monitoring
    Wisp.all.each do |wisp|
      if wisp.owmw_enabled?
        wisp.access_points.each do |ap|
          if ap.associated_user_counts.count > 0
            first_time = ap.associated_user_counts.first(:order => "created_at").created_at.change(:min => 0, :sec => 0)
            last_time = ap.associated_user_counts.first(:order => "created_at DESC").created_at.change(:min => 0, :sec => 0)
            avg = ap.associated_user_counts.average(:count, :conditions => ["created_at < ?", last_time]).to_f
            ah = ap.associated_user_count_histories.build(:count => avg, :start_time => first_time, :last_time => last_time)
            ah.save!
            AssociatedUserCount.destroy_all(["access_point_id = ? AND created_at < ?", ap.id, last_time])
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
