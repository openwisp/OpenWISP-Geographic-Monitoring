class Activity < ActiveRecord::Base
  belongs_to :access_point

  def status
    st = read_attribute :status
    st == 1
  end
end
