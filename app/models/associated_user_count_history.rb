class AssociatedUserCountHistory < ActiveRecord::Base
  belongs_to :access_point

  default_scope order(:start_time)

  def as_json(options={})
    # Time should be in unix epoch time in
    # milliseconds...
    [ start_time.to_i * 1000, count ]
  end

  def self.older_than(time)
    where(:start_time => time.to_time..6.hours.ago)
  end

  def self.observe(from, to)
    where(:last_time => from..to)
  end
end
