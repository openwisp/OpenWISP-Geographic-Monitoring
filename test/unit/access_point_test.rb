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
  
  test "test count methods" do
    assert_equal 4, AccessPoint.total.count
    assert_equal 1, AccessPoint.up.count
    assert_equal 1, AccessPoint.down.count
    assert_equal 2, AccessPoint.unknown.count
    assert_equal 2, AccessPoint.known.count
  end
end
