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
  
  test "Group join_all_wisp" do
    groups = Group.all_join_wisp
    assert groups[0].attributes.include?('wisp_name')
    
    groups = Group.all_join_wisp("wisp_id = ? OR wisp_id IS NULL", [1])
    assert groups[0].attributes.include?('wisp_name')
    
    groups = Group.all_join_wisp("wisp_id = ?", [1])
    assert groups[0].attributes.include?('wisp_name')
    assert groups.length == 2
  end
end