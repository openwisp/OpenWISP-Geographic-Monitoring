require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "uniqueness of email" do
    user = User.new({ :username => 'test1', :email => 'user@user.it', :password => 'tester03', :password_confirmation => 'tester03' })
    assert !user.save, 'should not save'
    assert user.errors.keys.include?(:email), 'erros has should contain email key'
    user.email = 'not_taken@user.it'
    assert user.save
  end
  
  test "first user role should be wisps_viewer" do
    assert User.available_roles[0].to_s == 'wisps_viewer'
  end
  
  test "User.roles_id method" do
    # should be empty
    assert User.new.roles_id == [], 'roles_id method should return empty array'
    assert User.new.roles_id.length <= 0, 'roles_id method should return an array of length less than or equal to 0'
    # should have 1
    admin = users(:admin)
    assert admin.roles_id.length == 1, 'admin should have 1 role assigned'
    # assign all roles to admin
    Wisp.create_all_roles
    all_roles = Role.all
    admin.roles = all_roles
    
    assert admin.roles.length == self.expected_roles_count, 'should have #{expected_roles_count} roles assigned'
  end
  
  test "assign_role method" do
    Wisp.create_all_roles
    user = users(:sfigato)
    user.assign_role('wisps_viewer')
    assert user.roles.length == 1, 'user should have 1 role assigned'
    user.assign_role('wisp_access_points_viewer', 1)
    assert user.roles(force_query=true).length == 2, 'user should have 2 roles assigned'
  end
  
  test "remove_role method" do
    Wisp.create_all_roles
    user = users(:sfigato)
    user.assign_role('wisps_viewer')
    user.remove_role(user.roles[0])
  end
  
  test "roles_search" do
    assert_equal 1, users(:brescia_admin).roles_search(:wisp_access_points_viewer).length
    assert_equal 0, users(:admin).roles_search(:wisp_access_points_viewer).length # because wisps_viewer role does not need wisp specific roles
    assert_equal 2, users(:mixed_operator).roles_search(:wisp_access_points_viewer).length
  end
  
  test "roles_include?" do
    assert users(:admin).roles_include?(:wisps_viewer), 'admin should be wisp viewer'
    assert !users(:admin).roles_include?(:wisp_access_points_viewer), 'admin should not be wisp_access_points_viewer'
    assert !users(:sfigato).roles_include?(:wisps_viewer), 'sfigato should not be wisp viewer'
    assert !users(:sfigato).roles_include?(:wisp_access_points_viewer), 'sfigato should not be wisp_access_points_viewer'
    assert !users(:mixed_operator).roles_include?(:wisps_viewer), 'mixed_operator should not be wisp viewer'
    assert users(:mixed_operator).roles_include?(:wisp_access_points_viewer, 1), 'mixed_operator should be wisp_access_points_viewer of wisp 2'
    assert users(:mixed_operator).roles_include?(:wisp_access_points_viewer, 2), 'mixed_operator should be wisp_access_points_viewer of wisp 3'
  end
end
