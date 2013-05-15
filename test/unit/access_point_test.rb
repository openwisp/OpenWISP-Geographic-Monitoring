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
  
  test "sorting" do
    
    def test_sorting(attr='id', direction='asc')
      prev = nil
    
      AccessPoint.with_properties_and_group.sort_with(attr, direction).each do |ap|
        unless prev.nil? or ap[attr].nil?
          # current value must be greater
          if direction == 'asc'
            # it must be higher or at least the same (not less)
            assert((ap[attr] > prev or ap[attr] == prev))
          else
            # it must be less or at least the same (not higher)
            assert((ap[attr] < prev or ap[attr] == prev))
          end
        else
          # assign previous
          prev = ap[attr]
        end
      end
    end
    
    test_sorting()
    test_sorting('id', 'desc')
    test_sorting('hostname', 'asc')
    test_sorting('hostname', 'desc')
    test_sorting('site_description', 'asc')
    test_sorting('site_description', 'desc')
    test_sorting('address', 'asc')
    test_sorting('address', 'desc')
    test_sorting('city', 'asc')
    test_sorting('city', 'desc')
    test_sorting('mac_address', 'asc')
    test_sorting('mac_address', 'desc')
    test_sorting('ip_address', 'asc')
    test_sorting('ip_address', 'desc')
    test_sorting('activation_date', 'asc')
    test_sorting('activation_date', 'desc')
    test_sorting('group', 'asc')
    test_sorting('group', 'desc')
    test_sorting('public', 'asc')
    test_sorting('public', 'desc')
    test_sorting('favourite', 'asc')
    test_sorting('favourite', 'desc')
  end
end
