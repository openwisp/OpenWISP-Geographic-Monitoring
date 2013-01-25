require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "unauthenticated user cannot get index" do
    get :index
    assert_redirected_to '/users/sign_in'
  end
  
  test "non wisp_viewer cannot get index" do
    sign_in users(:sfigato)
    assert_raise Acl9::AccessDenied do
      get :index
    end
  end
  
  test "wisp_viewer can get index" do
    sign_in users(:admin)
    get :index
    assert_response :success
  end
end
