require 'test_helper'

class WispsControllerTest < ActionController::TestCase
  setup do
    @wisp = wisps(:one)
  end

  test "should get index" do
    get :index
    assert_response :success
    assert_not_nil assigns(:wisps)
  end

  test "should get new" do
    get :new
    assert_response :success
  end

  test "should create wisp" do
    assert_difference('Wisp.count') do
      post :create, :wisp => @wisp.attributes
    end

    assert_redirected_to wisp_path(assigns(:wisp))
  end

  test "should show wisp" do
    get :show, :id => @wisp.to_param
    assert_response :success
  end

  test "should get edit" do
    get :edit, :id => @wisp.to_param
    assert_response :success
  end

  test "should update wisp" do
    put :update, :id => @wisp.to_param, :wisp => @wisp.attributes
    assert_redirected_to wisp_path(assigns(:wisp))
  end

  test "should destroy wisp" do
    assert_difference('Wisp.count', -1) do
      delete :destroy, :id => @wisp.to_param
    end

    assert_redirected_to wisps_path
  end
end
