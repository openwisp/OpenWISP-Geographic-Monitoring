require 'test_helper'

class AccessPointsControllerTest < ActionController::TestCase
  test "non wisp_viewer should get all access points" do
    sign_in users(:admin)
    get :index
    assert :success
  end
  
  test "non wisp_viewer should not get all access points" do
    sign_in users(:sfigato)
    get :index
    assert :forbidden
  end
end
