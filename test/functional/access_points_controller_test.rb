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

  test "get access points map of all" do
    sign_in users(:admin)
    get :index, { :format => 'json' }

    assert_response :success
  end

  test "get access points json simple" do
    sign_in users(:admin)
    get :index, { :format => 'json', :simple => 'true' }
    assert_response :success

    data = JSON::load(response.body)
    assert data.class == Array
    assert data[0]['access_point'].class == Hash
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

  test "get access point with wrong wisp" do
    sign_in users(:admin)
    @wisp = Wisp.find(2)
    get :show, { :wisp_id => @wisp.slug, :id => access_points(:wherecamp).id }
    assert_response 404
  end

  test "last logins" do
    sign_in users(:admin)
    @wisp = wisps(:provincia_wifi)

    CONFIG['last_logins'] = false
    get :show, { :wisp_id => @wisp.name, :id => access_points(:wherecamp).id }
    assert_response :success
    assert_select '#last-logins', 0

    CONFIG['last_logins'] = true
    Configuration.set('owmw_enabled', 'true', 'boolean')
    Configuration.set('wisps_with_owmw', '%s' % @wisp.name.gsub(' ', '-'), 'array')

    get :show, { :wisp_id => @wisp.name, :id => access_points(:wherecamp).id }
    assert_response :success
    assert_select '#last-logins', 1

    Configuration.set('owmw_enabled', 'false', 'boolean')
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

  test "batch change property" do
    sign_in users(:brescia_admin)
    # ensure property sets do not exist
    properties = PropertySet.find_by_access_point_id([3, 4])
    assert_nil properties
    # change group of ap with no property set
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => 5, :access_points => [3, 4] }
    assert_response :success
    ap = AccessPoint.find([3, 4])
    assert ap[0].properties.group_id == 5
    assert ap[1].properties.group_id == 5
    # 403: moving ap to group of another wisp for which user doesn't have authorization
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => 3, :access_points => [1, 2] }
    assert_response :forbidden
    # 403: moving ap of another wisp for which user doesn't have authorization to a group to which user controls
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => 5, :access_points => [1, 2] }
    assert_response :forbidden
    sign_out users(:brescia_admin)

    sign_in users(:sfigato)
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => 3, :access_points => [1, 2, 3] }
    assert_response :forbidden
    sign_out users(:sfigato)

    sign_in users(:admin)
    # 400: missing or bad parameter format
    post :batch_change_property, { :format => 'json' }
    assert_response :bad_request
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => 3 }
    assert_response :bad_request
    post :batch_change_property, { :format => 'json', :access_points => [1, 2, 3] }
    assert_response :bad_request
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => '', :access_points => [1, 2, 3] }
    assert_response :bad_request
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => 3, :access_points => [] }
    assert_response :bad_request
    post :batch_change_property, { :format => 'json', :property_name => 'unknown', :property_value => 3, :access_points => [1, 2, 3] }
    assert_response :bad_request

    # 404: not found
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => 10, :access_points => [1, 2, 3] }
    assert_response :not_found

    # 403: user is authorized but is trying to move ap in a group of another wisp
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => 3, :access_points => [3, 4] }
    assert_response :forbidden

    # ensure ap group changes
    ap = AccessPoint.find([1, 2])
    assert ap[0].properties.group_id != 3
    assert ap[1].properties.group_id != 3
    post :batch_change_property, { :format => 'json', :property_name => 'group_id', :property_value => 3, :access_points => [1, 2] }
    assert_response :success
    ap = AccessPoint.find([1, 2])
    assert_equal 3, ap[0].properties.group_id
    assert_equal 3, ap[1].properties.group_id

    # ensure public value changes
    post :batch_change_property, { :format => 'json', :property_name => 'public', :property_value => true, :access_points => [1, 2, 3] }
    assert_response :success
    ap = AccessPoint.find([1, 2, 3])
    assert ap[0].properties.public
    assert ap[1].properties.public
    assert ap[2].properties.public
    post :batch_change_property, { :format => 'json', :property_name => 'public', :property_value => false, :access_points => [1, 2, 3] }
    assert_response :success
    ap = AccessPoint.find([1, 2, 3])
    assert !ap[0].properties.public
    assert !ap[1].properties.public
    assert !ap[2].properties.public

    post :batch_change_property, { :format => 'json', :property_name => 'favourite', :property_value => true, :access_points => [1, 2, 3] }
    assert_response :success
    ap = AccessPoint.find([1, 2, 3])
    assert ap[0].properties.favourite
    assert ap[1].properties.favourite
    assert ap[2].properties.favourite
    post :batch_change_property, { :format => 'json', :property_name => 'favourite', :property_value => false, :access_points => [1, 2, 3] }
    assert_response :success
    ap = AccessPoint.find([1, 2, 3])
    assert !ap[0].properties.favourite
    assert !ap[1].properties.favourite
    assert !ap[2].properties.favourite
  end

  test "edit ap alert settings" do
    sign_in users(:admin)

    ap = AccessPoint.with_properties_and_group.find(1)

    post :edit_ap_alert_settings, {
      #:format => 'json',
      :access_point_id => 1,
      :wisp_id => ap.wisp_id,
      :alerts => 'true'
    }
    assert_response :success
    ap = AccessPoint.with_properties_and_group.find(1)
    assert_equal ap.properties.alerts, true
    assert ap.alert_settings_customized?

    post :edit_ap_alert_settings, {
      #:format => 'json',
      :access_point_id => 1,
      :wisp_id => ap.wisp_id,
      :alerts => 'false'
    }
    assert_response :success
    ap = AccessPoint.with_properties_and_group.find(1)
    assert_equal ap.properties.alerts, false

    post :edit_ap_alert_settings, {
      #:format => 'json',
      :access_point_id => 1,
      :wisp_id => ap.wisp_id,
      :alerts => 'true',
      :alerts_threshold_up => 20,
      :alerts_threshold_down => 30
    }
    assert_response :success
    ap = AccessPoint.with_properties_and_group.find(1)
    assert_equal ap.properties.alerts, true
    assert_equal ap.threshold_up, 20
    assert_equal ap.threshold_down, 30
    assert ap.alert_settings_customized?

    post :edit_ap_alert_settings, {
      #:format => 'json',
      :access_point_id => 1,
      :wisp_id => ap.wisp_id,
      :reset => 'true'
    }

    ap = AccessPoint.with_properties_and_group.find(1)
    assert !ap.alert_settings_customized?
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

  # TODO: this might be removed
  test "reset all favourites" do
    sign_in users(:admin)
    wisp = wisps(:provincia_wifi)

    AccessPoint.where(:wisp_id => wisp.id).each do |ap|
      ap.properties.favourite = true
      ap.properties.save!
    end

    get :reset_favourites, { :wisp_id => wisp.id }
    assert_redirected_to wisp_access_points_favourite_path(wisp)

    assert_equal 0, AccessPoint.with_properties.where(['wisp_id = ? AND favourite = 1', wisp.id]).count
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

  test "list ordering" do
    sign_in users(:admin)

    # DRY (don't repeat yourself) method
    def test_html_ordering(wisp=nil, attr='id', direction='asc')
      # set locale
      I18n.locale = 'en'
      # retrieve ap
      access_points = AccessPoint.with_properties_and_group.sort_with(attr, direction).scoped

      # filter wisp and retrieve HTML
      unless wisp.nil?
        access_points = access_points.of_wisp(wisp)
        if attr != 'id'
          get :index, { :wisp_id => wisp.name, :column => attr, :order => direction }
        else
          get :index, { :wisp_id => wisp.name }
        end
      else
        if attr != 'id'
          get :index, { :column => attr, :order => direction }
        else
          get :index
        end
      end

      # ensure ordering is correct
      assert_select "#access_points tr" do |elements|
        elements.each_with_index do |element, i|
          # if checking id we check the data-ap-id HTML attribute
          case attr
          when 'id'
            assert element.to_s.include?('data-ap-id="%s"' % access_points[i].id)
          when 'hostname'
            assert_select element, "td.#{attr} a", access_points[i][attr]
          when 'group'
            unless wisp.nil?
              assert_select element, "td.#{attr} a", access_points[i].group_name
            else
              assert_select element, "td.#{attr}", access_points[i].group_name
            end
          when 'public'
            # ensure is right image
            assert css_select(element, "td.#{attr}").to_s.include?(access_points[i].public? ? 'accept' : 'delete')
          when 'favourite'
            # ensure is right image
            assert css_select(element, "td.#{attr}").to_s.include?(access_points[i].favourite? ? 'star.png' : 'star-off.png')
          else
            assert_select element, "td.#{attr}", access_points[i][attr]
          end
        end
      end
    end

    test_html_ordering()
    test_html_ordering(nil, 'hostname', 'asc')
    test_html_ordering(nil, 'hostname', 'desc')
    test_html_ordering(nil, 'site_description', 'asc')
    test_html_ordering(nil, 'site_description', 'desc')
    test_html_ordering(nil, 'city', 'asc')
    test_html_ordering(nil, 'city', 'desc')
    test_html_ordering(nil, 'mac_address', 'asc')
    test_html_ordering(nil, 'mac_address', 'desc')
    test_html_ordering(nil, 'ip_address', 'asc')
    test_html_ordering(nil, 'ip_address', 'desc')
    test_html_ordering(nil, 'activation_date', 'asc')
    test_html_ordering(nil, 'activation_date', 'desc')
    test_html_ordering(nil, 'group', 'asc')
    test_html_ordering(nil, 'group', 'desc')
    test_html_ordering(nil, 'public', 'asc')
    test_html_ordering(nil, 'public', 'desc')
    test_html_ordering(nil, 'favourite', 'asc')
    test_html_ordering(nil, 'favourite', 'desc')

    provincia = wisps(:provincia_wifi)
    test_html_ordering(provincia)
    test_html_ordering(provincia, 'hostname', 'asc')
    test_html_ordering(provincia, 'hostname', 'desc')
    test_html_ordering(provincia, 'site_description', 'asc')
    test_html_ordering(provincia, 'site_description', 'desc')
    test_html_ordering(provincia, 'city', 'asc')
    test_html_ordering(provincia, 'city', 'desc')
    test_html_ordering(provincia, 'mac_address', 'asc')
    test_html_ordering(provincia, 'mac_address', 'desc')
    test_html_ordering(provincia, 'ip_address', 'asc')
    test_html_ordering(provincia, 'ip_address', 'desc')
    test_html_ordering(provincia, 'activation_date', 'asc')
    test_html_ordering(provincia, 'activation_date', 'desc')
    test_html_ordering(provincia, 'group', 'asc')
    test_html_ordering(provincia, 'group', 'desc')
    test_html_ordering(provincia, 'public', 'asc')
    test_html_ordering(provincia, 'public', 'desc')
    test_html_ordering(provincia, 'favourite', 'asc')
    test_html_ordering(provincia, 'favourite', 'desc')
  end

  test "t_column" do
    c = AccessPointsController.new
    assert_equal "hostname", c.instance_eval{ t_column(I18n.t(:Hostname).downcase) }
    assert_equal "site_description", c.instance_eval{ t_column(I18n.t(:Site_description).downcase) }
    assert_equal "address", c.instance_eval{ t_column(I18n.t(:Address).downcase) }
    assert_equal "city", c.instance_eval{ t_column(I18n.t(:City).downcase) }
    assert_equal "mac_address", c.instance_eval{ t_column(I18n.t(:Mac_address).downcase) }
    assert_equal "ip_address", c.instance_eval{ t_column(I18n.t(:Ip_addr).downcase) }
    assert_equal "activation_date", c.instance_eval{ t_column(I18n.t(:Activation_date).downcase) }
    assert_equal "group_name", c.instance_eval{ t_column(I18n.t(:Group).downcase) }
    assert_equal "public", c.instance_eval{ t_column(I18n.t(:Public).downcase) }
    assert_equal "favourite", c.instance_eval{ t_column(I18n.t(:Favourite).downcase) }
    assert_equal "status", c.instance_eval{ t_column(I18n.t(:Status).downcase) }
  end

  private

  def activemenu_test
    assert_select "#main-nav a.active", 1
    assert_select "#main-nav a.active", "%s&#x25BE;" % [I18n.t(:Access_points)]
  end
end
