require 'test_helper'

class AccessPointsControllerTest < ActionController::TestCase
  test "wisp_viewer should get all access points" do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_select '#access_points' do
      assert_select 'tr', AccessPoint.count
    end
  end
  
  test "get access points of wisp provinciawifi" do
    sign_in users(:admin)
    @wisp = wisps(:provincia_wifi)
    get :index, { :wisp_id => @wisp.name }
    assert_response :success
    assert_select '#access_points' do
      assert_select 'tr', AccessPoint.where(:wisp_id => @wisp.id).count
    end
  end
  
  test "get access points of wisp name containing space" do    
    def do_space_test
      @wisp = wisps(:freewifibrescia)
      get :index, { :wisp_id => @wisp.name.gsub(' ', '-') }
      assert_response :success
      assert_select '#access_points' do
        assert_select 'tr', AccessPoint.where(:wisp_id => @wisp.id).count
      end
    end
    
    sign_in users(:admin)
    do_space_test()
    sign_out users(:admin)
    
    sign_in users(:brescia_admin)
    do_space_test()
    sign_out users(:brescia_admin)
  end
  
  test "get access points with missing property_set" do
    sign_in users(:admin)
    @wisp = wisps(:freewifibrescia)
    get :show, { :wisp_id => @wisp.name.gsub(' ', '-'), :id => 3 }
    assert_response :success
    assert_select '#group-info', 'no group'
  end
  
  test "get access point wherecamp" do
    sign_in users(:admin)
    @wisp = wisps(:provincia_wifi)
    get :show, { :wisp_id => @wisp.name, :id => access_points(:wherecamp).id }
    assert_response :success
    assert_select '#group-info', 'no group'
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
  
  test "show access points by group" do
    sign_in users(:admin)
    # move all the ap in group public squares
    access_points = AccessPoint.where(:wisp_id => 1).limit(1)
    ap_count = access_points.length
    access_points.each do |ap|
      p = ap.properties
      p.group_id = groups(:squares_1).id
      p.save!
    end
    get :index, { :wisp_id => wisps(:provincia_wifi).name, :group_id => groups(:squares_1).id }
    assert_response :success
    assert_select '#access_points' do
      assert_select 'tr', ap_count
    end
  end
end