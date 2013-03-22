require 'test_helper'

class RoleTest < ActiveSupport::TestCase
  # Replace this with your real tests.
  test "test Role.all_join_wisp" do
    Wisp.create_all_roles
    roles = Role.all_join_wisp
    assert Role.all.length == 11
  end
end
