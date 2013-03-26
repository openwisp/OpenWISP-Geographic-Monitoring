require 'test_helper'

class UserTest < ActiveSupport::TestCase
  test "uniqueness of email" do
    user = User.new({ :username => 'test1', :email => 'user@user.it', :password => 'tester03' })
    assert !user.save, 'should not save'
    assert user.errors.keys.include?(:email), 'erros has should contain email key'
    user.email = 'not_taken@user.it'
    assert user.save
  end
  
  test "first user role should be wisp_viewer" do
    assert User.available_roles[0].to_s == 'wisps_viewer'
  end
  
  test "test User.roles_id method" do
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
    assert admin.roles.length == 11, 'should have 11 roles assigned'
  end
  
  test "test assign_role method" do
    Wisp.create_all_roles
    user = users(:sfigato)
    user.assign_role('wisp_viewer')
    assert user.roles.length == 1, 'user should have 1 role assigned'
    user.assign_role('wisp_access_points_viewer', 1)
    assert user.roles.length == 2, 'user should have 2 roles assigned'
  end
  
  test "test remove_role method" do
    Wisp.create_all_roles
    user = users(:sfigato)
    user.assign_role('wisp_viewer')
    user.remove_role(user.roles[0])
  end
end
