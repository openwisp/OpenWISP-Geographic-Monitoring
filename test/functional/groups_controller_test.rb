require 'test_helper'

class GroupsControllerTest < ActionController::TestCase
  test "unauthenticated user cannot get index" do
    get :index
    assert_redirected_to new_user_session_url
  end
  
  test "should get index" do
    sign_in users(:admin)
    get :index
    assert :success
    assert_select "table#group_list tbody" do
      assert_select "tr", 4
    end
  end
  
  test "should get new" do
    sign_in users(:admin)
    get :new
    assert :success
    assert_select "#group_form", 1
  end
  
  test "can create user" do
    sign_in users(:admin)
    group_count = Group.count
    # crete new user with 6 roles assigned
    post :create, :group => {
      :name => 'test general group',
      :description => 'test description yeah'
    }
    assert Group.count == group_count + 1, 'group count should have incremented of 1'
    new_group = Group.last
    assert new_group.name == 'test general group', 'name not been set as expected'
    assert new_group.description == 'test description yeah', 'description has not been set as expected'
    assert_redirected_to groups_path, 'should redirect to group list after success'
  end
  
  test "should get edit group" do
    sign_in users(:admin)
    get :edit, { :id => 1 }
    assert :success
    assert_select "#group_form", 1
  end
  
  test "should destroy group" do
    sign_in users(:admin)
    group_count = Group.count
    delete :destroy, { :id => 1 }
    assert_redirected_to groups_path, 'should redirect to group list after success'
    assert Group.count == group_count - 1
  end
end