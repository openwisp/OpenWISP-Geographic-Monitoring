class ActivityHistory < ActiveRecord::Base
  belongs_to :hotspot

  default_scope order(:start_time)

  def as_json(options={})
    # Time should be in unix epoch time in
    # milliseconds...
    [ start_time.to_i * 1000, status ]
  end

  def self.older_than(time)
    where(:start_time => time.to_time..Time.now)
  end

  def self.observe(from, to)
    where(:last_time => from..to)
  end

  def self.average_availability
     average('status').to_f * 100
  end
end
