class Activity < ActiveRecord::Base
  belongs_to :access_point

  default_scope order(:created_at)

  scope :recent, proc{ where("created_at > ?", 6.hours.ago) }
  scope :not_recent, proc{ where("created_at <= ?", 6.hours.ago) }

  def status
    st = read_attribute :status
    st == 1
  end
end
