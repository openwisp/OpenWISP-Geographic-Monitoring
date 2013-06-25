require 'test_helper'

class PropertySetsControllerTest < ActionController::TestCase
  test "should get update" do
    sign_in users(:admin)
    xhr :get, :update, { :wisp_id => wisps(:provincia_wifi).name, :access_point_id => 1, :property_set => ['reachable'] }
    assert_response :success
  end
end
