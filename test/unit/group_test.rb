require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  #test "check default group is there" do
  #  group = Group.find_by_id(1)
  #  assert group.id == 1
  #end
  
  test "test new group" do
    group = Group.new()
    # shouldn't save cos name is missing
    assert !group.save()
    assert group.errors.keys.include?(:name)
    group.name = 'test group'
    assert group.save()
  end
end