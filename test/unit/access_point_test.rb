require 'test_helper'

class AccessPointTest < ActiveSupport::TestCase
  test "batch_change_group" do
    AccessPoint.batch_change_group(3, [1, 2])
    
    assert_equal 3, AccessPoint.find(1).properties.group_id
    assert_equal 3, AccessPoint.find(2).properties.group_id
    
    AccessPoint.find(3, 4).each do |ap|
      assert_not_equal 3, ap.properties.group_id
    end
  end
end
