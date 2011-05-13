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

  def hotspots_monitoring
    threads = []
    Hotspot.all.each do |ap|

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

  def consolidate
    Hotspot.all.each do |ap|
      @@semaphore.synchronize {
        if ap.activities.count > 0
          first_time = ap.activities.first(:order => "created_at").created_at.change(:min => 0, :sec => 0)
          last_time = ap.activities.first(:order => "created_at DESC").created_at.change(:min => 0, :sec => 0)
          avg = ap.activities.average(:status, :conditions => ["created_at < ?", last_time]).to_f
          ah = ap.activity_histories.build(:status => avg, :start_time => first_time, :last_time => last_time)
          ah.save!
          Activity.destroy_all(["hotspot_id = ? AND created_at < ?", ap.id, last_time])
        end
      }
    end
  end

  def housekeeping
    time = 6.months.to_i.ago
    ActivityHistory.destroy_all(["created_at < ?", time])
  end

end
