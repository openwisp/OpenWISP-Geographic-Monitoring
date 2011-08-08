class AssociatedUserCountHistory < ActiveRecord::Base
  belongs_to :access_point

  def self.older_than(time)
    where(:start_time => time.to_time..Time.now)
  end
end
