require 'test_helper'

class WispsControllerTest < ActionController::TestCase
  setup do
    @wisp = wisps(:provincia_wifi)
  end
  
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
    assert_not_nil assigns(:wisps)
    # wisps_viewer can see all wisps
    assert_select "#wisp-list", 1 do
      assert_select "#wisp-list tbody tr", 3
    end
  end
  
  test "limited wisp index access" do
    sign_in users(:brescia_admin)
    get :index
    assert_response :success
    # brescia admin can see only 1 wisp
    assert_select "#wisp-list", 1 do
      assert_select "tbody tr", 1
    end
  end
end
