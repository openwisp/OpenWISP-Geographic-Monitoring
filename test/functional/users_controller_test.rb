require 'test_helper'

class UsersControllerTest < ActionController::TestCase
  test "only wisp viewer can get index" do
    get :index
    assert_redirected_to '/users/sign_in'
  end
  
  test "wisp_viewer should get index" do
    sign_in users(:admin)
    get :index
    assert_response :success
  end
end
