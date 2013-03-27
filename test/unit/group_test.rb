require 'test_helper'

class GroupTest < ActiveSupport::TestCase
  #test "check default group is there" do
  #  group = Group.find_by_id(1)
  #  assert group.id == 1
  #end
  
  test "new group" do
    group = Group.new()
    # shouldn't save cos name is missing
    assert !group.save()
    assert group.errors.keys.include?(:name)
    group.name = 'test group'
    assert group.save()
  end
  
  test "toggle_monitor!" do
    group = groups(:archived)
    # shouldn't save cos name is missing
    assert group.monitor == false, 'monitor attribute of archived group should be set to false in fixtures file'
    assert group.toggle_monitor!, 'should change from false to true'
    assert group.monitor, 'monitor attribute should have changed'
    group = Group.find(group.id)
    assert group.monitor, 'monitor attribute should be true'
    assert !group.toggle_monitor!, 'should change from true to false'
    assert group.monitor == false, 'monitor attribute should be false again'
  end
end