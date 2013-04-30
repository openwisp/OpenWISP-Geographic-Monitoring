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
    activemenu_test()
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
    activemenu_test()
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
  
  test "change group of a nonexistent propertyset" do
    sign_in users(:admin)
    # check fixture is correct, property set should not exist
    assert_nil PropertySet.find_by_access_point_id(3)
    # it should succeed anyway because the property set will be created
    post :change_group, { :format => 'json', :wisp_id => 'freewifi brescia', :access_point_id => 3, :group_id => 5 }
    assert_response :success
  end
  
  test "change group 404" do
    sign_in users(:admin)
    # check fixture is correct
    assert PropertySet.find_by_access_point_id(1).group_id == 1
    # POST change group to a group that does not exist
    post :change_group, { :format => 'json', :wisp_id => 'provinciawifi', :access_point_id => 1, :group_id => 10 }
    assert_response :not_found
  end
  
  test "change group of another wisp" do
    sign_in users(:admin)
    # group_id 2 is of WISP provincia wifi so we should not be allowed
    post :change_group, { :format => 'json', :wisp_id => 'freewifi brescia', :access_point_id => 3, :group_id => 2 }
    assert_response :not_found
  end
  
  test "change group of a nonexistent AP" do
    sign_in users(:admin)
    post :change_group, { :format => 'json', :wisp_id => 'freewifi brescia', :access_point_id => 99, :group_id => 5 }
    assert_response :not_found
  end
  
  test "batch change group" do
    sign_in users(:sfigato)
    post :batch_change_group, { :format => 'json', :group_id => 3, :access_points => [1, 2, 3] }
    assert_response :forbidden
    sign_out users(:sfigato)
    
    sign_in users(:brescia_admin)
    # 403: moving ap to group of another wisp for which user doesn't have authorization
    post :batch_change_group, { :format => 'json', :group_id => 3, :access_points => [1, 2] }
    assert_response :forbidden
    # 403: moving ap of another wisp for which user doesn't have authorization to a group to which user controls
    post :batch_change_group, { :format => 'json', :group_id => 5, :access_points => [1, 2] }
    assert_response :forbidden
    sign_out users(:brescia_admin)
    
    sign_in users(:admin)
    # 400: missing or bad parameter format
    post :batch_change_group, { :format => 'json' }
    assert_response :bad_request
    post :batch_change_group, { :format => 'json', :group_id => 3 }
    assert_response :bad_request
    post :batch_change_group, { :format => 'json', :access_points => [1, 2, 3] }
    assert_response :bad_request
    post :batch_change_group, { :format => 'json', :group_id => '', :access_points => [1, 2, 3] }
    assert_response :bad_request
    post :batch_change_group, { :format => 'json', :group_id => 3, :access_points => [] }
    assert_response :bad_request
    
    # 404: not found
    post :batch_change_group, { :format => 'json', :group_id => 10, :access_points => [1, 2, 3] }
    assert_response :not_found
    
    # 403: user is authorized but is trying to move ap in a group of another wisp 
    post :batch_change_group, { :format => 'json', :group_id => 3, :access_points => [3, 4] }
    assert_response :forbidden
    
    # ensure ap group changes
    ap = AccessPoint.find([1, 2])
    assert ap[0].properties.group_id != 3
    assert ap[1].properties.group_id != 3
    post :batch_change_group, { :format => 'json', :group_id => 3, :access_points => [1, 2] }
    assert_response :success
    ap = AccessPoint.find([1, 2])
    assert_equal 3, ap[0].properties.group_id
    assert_equal 3, ap[1].properties.group_id
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
    
    wisp = wisps(:provincia_wifi)
    group = groups(:squares_1)
    
    get :index, { :wisp_id => wisp.name, :group_id => group.id }
    
    # TODO: problem here :(
    assert_routing(wisp_group_access_points_path(wisp, group), { :controller => 'access_points', :action => 'index', :wisp_id => wisp.name, :group_id => group.id.to_s })
    
    assert_equal wisp_group_access_points_path(wisp, group), request.path
    puts "\n\n\n%s\n\n\n" % [request.path]
    
    assert_response :success
    assert_select '#access_points' do
      assert_select 'tr', ap_count
    end
    activemenu_test()
  end
  
  test "show access points by wrong group" do
    sign_in users(:admin)
    # TODO: this also does not work as expected
    get :index, { :wisp_id => wisps(:provincia_wifi).name, :group_id => groups(:brescia_group1).id }
    assert_response :not_found
  end
  
  test "show empty access point list" do
    sign_in users(:admin)
    get :index, { :wisp_id => 'small wisp' }
    assert_response :success
    assert_select '.empty-page-msg', I18n.t(:No_AP)
    
    get :index, { :wisp_id => 'small wisp', :group_id => groups(:small_group).id }
    
    # TODO: this also does not work as expected
    assert_equal wisp_group_access_points_path(wisps(:small), groups(:small_group)), request.path
    
    assert_response :success
    assert_select '.empty-page-msg', I18n.t(:No_AP)
    activemenu_test()
  end
  
  test "toggle_public" do
    sign_in users(:admin)
    ap = access_points(:wherecamp)
    public_value = ap.properties.public
    post :toggle_public, { :format => 'json', :wisp_id => ap.wisp.name, :id => ap.id }
    assert_response :success
    assert_equal !public_value, AccessPoint.find(ap.id).public
  end
  
  private
  
  def activemenu_test
    assert_select "#main-nav a.active", 1
    assert_select "#main-nav a.active", "%s&#x25BE;" % [I18n.t(:Access_points)]
  end
end