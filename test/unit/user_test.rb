require 'test_helper'

class UserTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "first user role should be wisp_viewer" do
    assert User.available_roles[0].to_s == 'wisps_viewer'
  end
end
