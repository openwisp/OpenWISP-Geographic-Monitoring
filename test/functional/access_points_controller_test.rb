require 'test_helper'

class AccessPointsControllerTest < ActionController::TestCase
  test "non wisp_viewer should get all access points" do
    sign_in users(:admin)
    get :index
    assert_response :success
  end
  
  test "non wisp_viewer should not get all access points" do
    sign_in users(:sfigato)
    get :index
    assert_response :forbidden
  end
  
  test "select groups" do
    sign_in users(:admin)
    get :select_group, { :wisp_id => 'provinciawifi', :access_point_id => 1 }
    assert_response :success
    assert_select "#select-group", 1
    assert_select "#select-group tbody tr", 4
  end
  
  test "change group" do
    sign_in users(:admin)
    # check fixture is correct
    assert PropertySet.find_by_access_point_id(1).group_id == 1
    # POST change group to group with id 2
    post :change_group, { :format => 'json', :wisp_id => 'provinciawifi', :access_point_id => 1, :group_id => 2 }
    assert_response :success
    # ensure group has changed
    assert PropertySet.find_by_access_point_id(1).group_id == 2, 'group change failed'
  end
end