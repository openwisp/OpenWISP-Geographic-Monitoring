require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "test Role.all_join_wisp" do
    Wisp.create_all_roles
    roles = Role.all_join_wisp
    # expected roles forumla explained:
    # ([ALL_ROLES_COUNT] - [:wisps_viewer]) * [ALL_WISP_COUNT] + [:wisp_viewer]
    expected_roles_count = (User.available_roles.length - 1) * Wisp.all.count + 1
    assert_equal expected_roles_count, Role.all.length
  end
end
