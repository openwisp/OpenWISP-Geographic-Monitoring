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
  
  test "wisp id should be accepted too" do
    sign_in users(:admin)
    @wisp = wisps(:provincia_wifi)
    # both as number and as string
    get :index, { :wisp_id => @wisp.id }
    get :index, { :wisp_id => @wisp.id.to_s }
    
    assert_response :success
    assert_select '#access_points' do
      assert_select 'tr', AccessPoint.where(:wisp_id => @wisp.id).count
    end
    activemenu_test()
  end
  
  test "get access points map of wisp provinciawifi" do
    sign_in users(:admin)
    @wisp = wisps(:provincia_wifi)
    get :index, { :format => 'json', :wisp_id => @wisp.name }
    
    assert_response :success
  end
  
  test "get access points map of group of wisp provinciawifi" do
    # change group of AP for testing purpose
    ap = access_points(:eduroam)
    ap.properties.group_id = 2
    ap.properties.save!
    
    sign_in users(:admin)
    @wisp = wisps(:provincia_wifi)
    get :index, { :format => 'json', :wisp_id => @wisp.name, :group_id => 2 }
    assert_response :success
    
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert_equal 1, json_response.length
  end
  
  test "get access points map of provinciawifi favourites" do
    sign_in users(:admin)
    @wisp = wisps(:provincia_wifi)
    get :index, { :format => 'json', :wisp_id => @wisp.name, :filter => 'favourite' }
    assert_response :success
    
    json_response = ActiveSupport::JSON.decode(@response.body)
    assert_equal 1, json_response.length
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
  
  test "show access point correct published icon" do
    sign_in users(:admin)
    @wisp = wisps(:provincia_wifi)
    
    get :show, { :wisp_id => @wisp.name, :id => access_points(:wherecamp).id }
    assert css_select('.toggle-public img').to_s.include?('delete.png'), 'picture should indicate that the access point is not published'
    
    access_points(:wherecamp).properties.public = true
    access_points(:wherecamp).properties.save!
    get :show, { :wisp_id => @wisp.name, :id => access_points(:wherecamp).id }
    assert css_select('.toggle-public img').to_s.include?('accept.png'), 'picture should indicate that the access point is published'
    
    get :show, { :wisp_id => @wisp.name, :id => access_points(:eduroam).id }
    assert css_select('.toggle-public img').to_s.include?('delete.png'), 'picture should indicate that the access point is not published'
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
    assert_select "#select-group tbody tr", 5
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
    sign_in users(:brescia_admin)
    # ensure property sets do not exist
    properties = PropertySet.find_by_access_point_id([3, 4])
    assert_nil properties
    # change group of ap with no property set
    post :batch_change_group, { :format => 'json', :group_id => 5, :access_points => [3, 4] }
    assert_response :success
    ap = AccessPoint.find([3, 4])
    assert ap[0].properties.group_id == 5
    assert ap[1].properties.group_id == 5
    # 403: moving ap to group of another wisp for which user doesn't have authorization
    post :batch_change_group, { :format => 'json', :group_id => 3, :access_points => [1, 2] }
    assert_response :forbidden
    # 403: moving ap of another wisp for which user doesn't have authorization to a group to which user controls
    post :batch_change_group, { :format => 'json', :group_id => 5, :access_points => [1, 2] }
    assert_response :forbidden
    sign_out users(:brescia_admin)
    
    sign_in users(:sfigato)
    post :batch_change_group, { :format => 'json', :group_id => 3, :access_points => [1, 2, 3] }
    assert_response :forbidden
    sign_out users(:sfigato)
    
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
    
    get :index, { :id => wisp.name, :group_id => group.id }
    
    assert_response :success
    assert_select '#access_points' do
      assert_select 'tr', ap_count
    end
    activemenu_test()
  end
  
  test "show access points by wrong group" do
    sign_in users(:admin)
    get :index, { :wisp_id => wisps(:provincia_wifi).name, :group_id => groups(:brescia_group1).id }
    assert_response :not_found
  end
  
  test "show empty access point list" do
    sign_in users(:admin)
    get :index, { :wisp_id => 'small wisp' }
    
    assert_response :success
    assert_select '.empty-page-msg', I18n.t(:No_AP)
    
    get :index, { :wisp_id => 'small wisp', :group_id => groups(:small_group).id }
     
    assert_response :success
    assert_select '.empty-page-msg', I18n.t(:No_AP)
    activemenu_test()
  end
  
  test "search access points" do
    sign_in users(:admin)
    
    # search for "where" should return 1 ap
    get :index, { :wisp_id => wisps(:provincia_wifi).name, :q => 'where' }
    assert_response :success
    assert_select '#access_points' do
      assert_select 'tr', 1
    end
    
    # search "doesnotexist" should return 0 ap
    get :index, { :wisp_id => wisps(:provincia_wifi).name, :q => 'doesnotexist' }
    assert_response :success
    assert_select '#access_points tr', false
    
    # search "where" in a group where there are no access points should return 0 ap
    get :index, { :wisp_id => wisps(:provincia_wifi).name, :group_id => 2, :q => 'where' }
    assert_response :success
    assert_select '#access_points tr', false
    
    get :index, { :wisp_id => wisps(:provincia_wifi).name, :q => 'testing-test' }
    assert_response :success
    assert_select '#access_points tr', 1
    
    get :index, { :wisp_id => wisps(:provincia_wifi).name, :q => '00:27:22:27:42:40' }
    assert_response :success
    assert_select '#access_points tr', 1
    
    get :index, { :wisp_id => wisps(:provincia_wifi).name, :q => '10.8.1.82' }
    assert_response :success
    assert_select '#access_points tr', 1
  end
  
  test "search form action url" do
    sign_in users(:admin)
    wisp = wisps(:provincia_wifi)
    
    # all access points
    get :index
    assert_select '#access_points_quicksearch form[action=?]', access_points_path
    
    # access points > wisp
    get :index, { :wisp_id => wisp.name }
    assert_select '#access_points_quicksearch form[action=?]', wisp_access_points_path(wisp)
    
    # access points > wisp favourite
    get :index, { :wisp_id => wisp.name, :filter => 'favourite' }
    assert_response :success
    assert_select "#access_points_quicksearch form[action=?]", wisp_access_points_favourite_path(wisp)
    
    # access points > wisp > group
    get :index, { :wisp_id => wisp.name, :group_id => 1 }
    assert_select '#access_points_quicksearch form[action=?]', wisp_group_access_points_path(wisp, 1)
  end
  
  test "toggle_public" do
    sign_in users(:admin)
    ap = access_points(:wherecamp)
    public_value = ap.properties.public?
    post :toggle_public, { :format => 'json', :wisp_id => ap.wisp.name, :id => ap.id }
    assert_response :success
    assert_equal !public_value, PropertySet.find_by_access_point_id(ap.id).public
    assert_equal !public_value, ActiveSupport::JSON.decode(@response.body)['public']
    # repeat the operation
    post :toggle_public, { :format => 'json', :wisp_id => ap.wisp.name, :id => ap.id }
    assert_response :success
    assert_equal public_value, PropertySet.find_by_access_point_id(ap.id).public
    assert_equal public_value, ActiveSupport::JSON.decode(@response.body)['public']
    # repeat the operation using an integer for the ID
    post :toggle_public, { :format => 'json', :wisp_id => ap.wisp.id, :id => ap.id }
    assert_response :success
    assert_equal !public_value, PropertySet.find_by_access_point_id(ap.id).public
    assert_equal !public_value, ActiveSupport::JSON.decode(@response.body)['public']
    # repeat the operation using an integer for the ID
    post :toggle_public, { :format => 'json', :wisp_id => ap.wisp.id, :id => ap.id }
    assert_response :success
    assert_equal public_value, PropertySet.find_by_access_point_id(ap.id).public
    assert_equal public_value, ActiveSupport::JSON.decode(@response.body)['public']
  end
  
  test "toggle_favourite" do
    sign_in users(:admin)
    ap = access_points(:wherecamp)
    favourite_value = ap.properties.favourite?
    post :toggle_favourite, { :format => 'json', :wisp_id => ap.wisp.name, :id => ap.id }
    assert_response :success
    assert_equal !favourite_value, PropertySet.find_by_access_point_id(ap.id).favourite
    assert_equal !favourite_value, ActiveSupport::JSON.decode(@response.body)['favourite']
    # repeat the operation
    post :toggle_favourite, { :format => 'json', :wisp_id => ap.wisp.name, :id => ap.id }
    assert_response :success
    assert_equal favourite_value, PropertySet.find_by_access_point_id(ap.id).favourite
    assert_equal favourite_value, ActiveSupport::JSON.decode(@response.body)['favourite']
    # repeat the operation using an integer for the ID
    post :toggle_favourite, { :format => 'json', :wisp_id => ap.wisp.id, :id => ap.id }
    assert_response :success
    assert_equal !favourite_value, PropertySet.find_by_access_point_id(ap.id).favourite
    assert_equal !favourite_value, ActiveSupport::JSON.decode(@response.body)['favourite']
    # repeat the operation using an integer for the ID
    post :toggle_favourite, { :format => 'json', :wisp_id => ap.wisp.id, :id => ap.id }
    assert_response :success
    assert_equal favourite_value, PropertySet.find_by_access_point_id(ap.id).favourite
    assert_equal favourite_value, ActiveSupport::JSON.decode(@response.body)['favourite']
    
    # make 1 ap favourite from nil
    ap.properties.favourite = nil
    ap.properties.save!
    post :toggle_favourite, { :format => 'json', :wisp_id => ap.wisp.id, :id => ap.id }
    assert_response :success
    assert_equal true, PropertySet.find_by_access_point_id(ap.id).favourite
    assert_equal true, ActiveSupport::JSON.decode(@response.body)['favourite']
  end
  
  test "toggle_favourite url" do
    sign_in users(:admin)
    wisp = wisps(:provincia_wifi)
    access_point = access_points(:wherecamp)
    
    # detail ap
    get :show, { :wisp_id => wisp.id, :id => access_point.id }
    assert_response :success
    assert_select ".toggle-favourite[data-href=?]", toggle_favourite_wisp_access_point_path(wisp.id, access_point.id)
    
    # list ap
    get :index, { :wisp_id => wisp.name }
    assert_response :success
    found = false
    css_select(".toggle-favourite").each do |tag|
      if tag.to_s.include?(toggle_favourite_wisp_access_point_path(wisp.id, 6).to_s)
        found = true
        break
      end
    end
    assert found
  end
  
  test "favourite ap list and search" do
    sign_in users(:mixed_operator)
    wisp = wisps(:provincia_wifi)
    access_point = access_points(:wherecamp)
    
    # 1 favourite ap
    get :index, { :wisp_id => wisp.id, :filter => 'favourite' }
    assert_response :success
    assert_equal 1, css_select("tbody#access_points tr").length
    
    get :index, { :wisp_id => wisp.id, :filter => 'favourite', :q => 'eduroam' }
    assert_equal 0, css_select("tbody#access_points tr").length
    
    get :index, { :wisp_id => wisp.id, :filter => 'favourite', :q => 'wherecamp' }
    assert_equal 1, css_select("tbody#access_points tr").length
    
    # make 1 ap favourite from nil
    access_point.properties.favourite = nil
    access_point.properties.save!
    # now should find 1 in the list
    get :index, { :wisp_id => wisp.id, :filter => 'favourite' }
    assert_response :success
    assert_equal 0, css_select("tbody#access_points tr").length
  end
  
  test "georss" do
    sign_in users(:admin)
    wisp = wisps(:provincia_wifi)
    
    access_points = AccessPoint.where(:wisp_id => wisp.id)
    access_points.each do |ap|
      ap.properties.public = true
      ap.properties.save!
    end
    
    get :index, { :format => 'rss', :wisp_id => wisp.id }
    assert_response :success
    assert_select 'item', access_points.length
    
    get :index, { :format => 'rss', :wisp_id => wisp.id, :details => true }
    assert_response :success
    assert_select 'category', access_points.length
  end
  
  private
  
  def activemenu_test
    assert_select "#main-nav a.active", 1
    assert_select "#main-nav a.active", "%s&#x25BE;" % [I18n.t(:Access_points)]
  end
end