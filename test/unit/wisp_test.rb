require 'test_helper'

class WispTest < ActiveSupport::TestCase
  
  test "test wisp.create_roles" do
    assert_equal 4, Role.count
    wisps(:provincia_wifi).create_roles
    assert_equal 8, Role.count, 'this needs to be mantained manually'
    assert_equal 5, Role.where(:authorizable_id => 1).count
  end
  
  test "test Wisp.create_all_roles" do
    assert_equal 4, Role.count
    Wisp.create_all_roles
    assert Role.count == self.expected_roles_count
    assert_equal 5, Role.where(:authorizable_id => 1).count, 'expected 5 roles with authorizable_id == 1'
    assert_equal 5, Role.where(:authorizable_id => 2).count, 'expected 5 roles with authorizable_id == 2'
    assert_equal 5, Role.where(:authorizable_id => 3).count, 'expected 5 roles with authorizable_id == 3'
  end
  
  test "test wisp.count_access_points" do
    wisp = wisps(:provincia_wifi)
    assert_equal 1, wisp.count_access_points(:up)
    assert_equal 1, wisp.count_access_points(:down)
    assert_equal 0, wisp.count_access_points(:unknown)
    assert_equal 0, wisp.count_access_points('unknown')
    assert_equal 2, wisp.count_access_points(:total)
    assert_equal 2, wisp.count_access_points
    assert_raise ArgumentError do
      wisp.count_access_points(:wrong_parameter)
    end
    assert_equal 1, wisp.count_access_points(:favourite)
    
    wisp = wisps(:freewifibrescia)
    assert_equal 0, wisp.count_access_points(:up)
    assert_equal 0, wisp.count_access_points(:down)
    assert_equal 2, wisp.count_access_points(:unknown)
    assert_equal 2, wisp.count_access_points(:total)
    assert_equal 0, wisp.count_access_points(:favourite)
  end
  
  test "owmw_enabled" do
    Wisp.all.each do |wisp|
      assert_equal false, wisp.owmw_enabled?
    end
    
    Configuration.set('owmw_enabled', true, 'boolean')
    Configuration.set('wisps_with_owmw', 'provinciawifi, freewifi brescia, small wisp', 'array')
    
    Wisp.all.each do |wisp|
      assert_equal true, wisp.owmw_enabled?
    end
  end
end
