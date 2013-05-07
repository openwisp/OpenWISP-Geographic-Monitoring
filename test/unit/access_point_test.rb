require 'test_helper'

class AccessPointTest < ActiveSupport::TestCase
  test "batch_change_group" do
    AccessPoint.batch_change_group([1, 2], 3)
    
    assert_equal 3, AccessPoint.find(1).properties.group_id
    assert_equal 3, AccessPoint.find(2).properties.group_id
    
    AccessPoint.find(3, 4).each do |ap|
      assert_not_equal 3, ap.properties.group_id
    end
  end
  
  test "build_all_properties" do
    AccessPoint.build_all_properties()
    # ensure all group names are present
    AccessPoint.with_properties_and_group.each do |ap|
      assert_not_nil ap.group_name
    end
  end
end
