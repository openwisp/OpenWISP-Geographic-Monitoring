require 'test_helper'

class GroupsControllerTest < ActionController::TestCase  
  test "unauthenticated user cannot get index" do
    get :index
    assert_redirected_to new_user_session_url
  end
  
  test "group index permissions" do
    sign_in users(:sfigato)
    get :index
    assert_response :forbidden, 'sfigato should not get group index'
    sign_out users(:sfigato)
    
    sign_in users(:brescia_admin)
    get :index
    assert_response :success, 'brescia_admin should get group index'
    assert_select "table#group_list tbody" do
      assert_select "tr", 3, "brescia_admin should see only 3 records"
    end
    
    sign_out users(:brescia_admin)
    sign_in users(:mixed_operator)
    get :index
    assert_response :success, 'mixed_operator should get group index'
    assert_select "table#group_list tbody" do
      assert_select "tr", 6, "mixed_operator should only 6 records"
    end
  end
    
  test "should get index" do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_select "table#group_list tbody" do
      assert_select "tr", Group.all.count
    end
    activemenu_test()
  end
  
  test "should get new" do
    sign_in users(:admin)
    get :new
    assert_response :success
    assert_select "#group_form", 1
    activemenu_test()
  end
  
  test "can create group" do
    sign_in users(:admin)
    group_count = Group.count
    # crete new user with 6 roles assigned
    post :create, :group => {
      :name => 'test general group',
      :description => 'test description yeah'
    }
    assert Group.count == group_count + 1, 'group count should have incremented of 1'
    new_group = Group.last
    assert new_group.name == 'test general group', 'name not been set as expected'
    assert new_group.description == 'test description yeah', 'description has not been set as expected'
    assert_redirected_to groups_path, 'should redirect to group list after success'
  end
  
  test "should get edit group" do
    sign_in users(:admin)
    get :edit, { :id => 1 }
    assert_response :success
    assert_select "#group_form", 1
    assert_select "#group_wisp_id option", Wisp.all_accessible_to(users(:admin)).count
    
    sign_out users(:admin)
    sign_in users(:brescia_admin)
    get :edit, { :id => 1 }
    assert_select "#group_wisp_id option", Wisp.all_accessible_to(users(:brescia_admin)).count
  end
  
  test "should destroy group" do
    sign_in users(:admin)
    group_count = Group.count
    delete :destroy, { :id => 2 }
    assert_redirected_to groups_path, 'should redirect to group list after success'
    assert Group.count == group_count - 1
  end
  
  test "should not find delete button for default group" do
    sign_in users(:admin)
    get :index
    assert_response :success
    assert_select "#group_list tbody tr:first-child td:last-child", ""
  end
  
  test "should not destroy group 1" do
    sign_in users(:admin)
    group_count = Group.count
    delete :destroy, { :id => 1 }
    assert Group.count == group_count
    default_group = Group.find(1)
    assert !default_group.nil?
  end
  
  test "should get wisp group list" do
    sign_in users(:admin)
    wisp = wisps(:provincia_wifi)
    get :list, { :wisp_id => wisp.name }
    assert_response :success
    assert_select "table#group_list tbody" do
      assert_select "tr", 5
    end
    activemenu_test()
  end
  
  test "toggle count stats" do
    sign_in users(:admin)
    group = groups(:archived)
    count_stats_value = group.count_stats
    # toggle first time
    post :toggle_count_stats, { :format => 'json', :id => group.id }
    assert_response :success
    assert_equal !count_stats_value, Group.find(group.id).count_stats
    assert_equal !count_stats_value, ActiveSupport::JSON.decode(@response.body)['count_stats']
    # toggle second time
    post :toggle_count_stats, { :format => 'json', :id => group.id }
    assert_response :success
    assert_equal count_stats_value, Group.find(group.id).count_stats
    assert_equal count_stats_value, ActiveSupport::JSON.decode(@response.body)['count_stats']
  end
  
  private
  
  def activemenu_test
    assert_select "#main-nav a.active", 1
    assert_select "#main-nav a.active", I18n.t(:Groups)
  end
end