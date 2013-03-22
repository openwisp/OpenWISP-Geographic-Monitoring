require 'test_helper'

class WispTest < ActiveSupport::TestCase
  
  test "test wisp.create_roles" do
    assert Role.all.length == 1
    wisps(:provincia_wifi).create_roles
    assert Role.all.length == 6
    assert Role.where(:authorizable_id => 1).length == 5
  end
  
  test "test Wisp.create_all_roles" do
    assert Role.all.length == 1
    Wisp.create_all_roles
    assert Role.all.length == 11
    assert Role.where(:authorizable_id => 1).length == 5
    assert Role.where(:authorizable_id => 2).length == 5
  end
end
