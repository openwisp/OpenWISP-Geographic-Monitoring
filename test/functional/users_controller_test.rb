require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "unauthenticated user cannot get index" do
    get :index
    assert_redirected_to new_user_session_url
  end
  
  test "non wisp_viewer cannot get index" do
    sign_in users(:sfigato)
    get :index
    assert_response :forbidden
  end
  
  test "wisp_viewer can get index" do
    sign_in users(:admin)
    get :index
    assert_response :success
    activemenu_test()
  end
  
  test "wisp_viewer can get show" do
    sign_in users(:admin)
    get :show, :id => 1
    assert_response :success
    activemenu_test()
  end
  
  test "wisp_viewer can get edit" do
    sign_in users(:admin)
    assert Role.count == 4, 'there should be only 4 role in the DB'
    get :edit, :id => 1
    assert Role.count == self.expected_roles_count, 'there should be #{expected_roles_count] roles in the DB now'
    assert_response :success
    activemenu_test()
  end
  
  test "wisp_viewer can edit user" do
    sign_in users(:admin)
    # simple edit
    post :update, :id => 2, :user => {
      :username => 'user_test',
      :email => 'test_user@user.it'
    }
    user = users(:sfigato)
    assert user.username == 'user_test', 'username has not changed'
    assert user.email == 'test_user@user.it', 'email has not changed'
    assert_redirected_to users_path, 'should redirect to user list after success'
    
    # complex edit (edit roles too)
    assert user.roles.length < 1, 'user should not have any role'
    post :update, :id => 2, :user => {
      :username => 'user',
      :email => 'user@user.it'
    }, :roles => [1]
    assert_redirected_to users_path
    
    assert user.roles(force_query=true).length >= 1, 'user should have 1 role assigned'
    
    # simple edit should fail
    user_count = User.count
    post :update, :id => 2, :user => {
      :username => 'user_test',
      :email => 'admin@admin.it'
    }
    # response is not a redirect to user list
    assert_response :success
    # should find errors
    assert_select "#errorExplanation", 1
  end
  
  test "wisp_viewer can get new" do
    sign_in users(:admin)
    assert Role.count == 4, 'there should be only 4 role in the DB'
    get :new
    assert_response :success
    assert Role.count == self.expected_roles_count, 'there should be #{expected_roles_count] roles in the DB now'
    activemenu_test()
  end
  
  test "wisp_viewer can create user" do
    sign_in users(:admin)
    # create all roles
    Wisp.create_all_roles
    # crete new user with 6 roles assigned
    post :create, :user => {
      :username => 'new_user',
      :email => 'new_user@testing.com'
    }, :roles => Role.last(6)
    new_user = User.last
    assert new_user.username == 'new_user', 'username has not been set as expected'
    assert new_user.email == 'new_user@testing.com', 'email has not been set as expected'
    assert_redirected_to users_path, 'should redirect to user list after success'
    assert new_user.roles.length == 6, 'should have 6 roles assigned'
    
    # should fail
    user_count = User.count
    post :create, :user => {
      :username => 'new_user2',
      :email => 'new_user@testing.com'
    }, :roles => Role.last(6)
    # response is not a redirect to user list
    assert_response :success
    # user total is the same as before because the operation did not succeed
    assert user_count == User.count, 'user count should not have changed'
    assert_select "#errorExplanation", 1
  end
  
  test "create user with wisp_viewer" do
    sign_in users(:admin)
    assert_difference('User.count') do
      post :create, :user => {
        :username => 'new_user3',
        :email => 'new_user3@testing.com'
      }, :roles => Role.find_by_name('wisp_viewer')
    end
    assert_redirected_to users_path, 'should redirect to user list after success'
  end
  
  test "wisp_viewer can delete user" do
    sign_in users(:admin)
    assert_difference('User.count', -1) do
      get :destroy, :id => 2
    end
    assert_redirected_to users_path, 'should redirect to user list after successful delete operation'
  end
  
  private
  
  def activemenu_test
    assert_select "#main-nav a.active", 1
    assert_select "#main-nav a.active", I18n.t(:Users)
  end
end
