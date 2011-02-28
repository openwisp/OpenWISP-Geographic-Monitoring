class ActivityHistory < ActiveRecord::Base
  belongs_to :hotspot

  def as_json(options={})
    {:activity_history => {
      :status => status,
      :start_time => start_time.to_s,
      :last_time => last_time.to_s
    }}
  end
end
