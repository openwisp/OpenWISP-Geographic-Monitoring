class Activity < ActiveRecord::Base
  belongs_to :hotspot

  def status
    st = read_attribute :status
    st == 1
  end
end
