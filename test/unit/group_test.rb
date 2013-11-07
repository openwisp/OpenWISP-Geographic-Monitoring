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
  
  test "edit group" do
    group = Group.find(2)
    
    # all alert related fields are not set but this does not interfere with normal saving
    assert group.save()
    
    group.alerts = true
    group.alerts_email = 'test@test.com'
    
    # test alerts_threshold_up not a number
    group.alerts_threshold_up = 'f'
    group.alerts_threshold_down = 1
    assert !group.save()
    assert(group.errors.length == 1 && group.errors.include?(:alerts_threshold_up))
    
    # test alerts_threshold_up less than 0
    group.alerts_threshold_up = -1
    assert !group.save()
    assert(group.errors.length == 1 && group.errors.include?(:alerts_threshold_up))
    
    group.alerts_threshold_up = -1
    assert !group.save()
    assert(group.errors.length == 1 && group.errors.include?(:alerts_threshold_up))
    
    # test alerts_threshold_down not a number
    group.alerts_threshold_down = 'f'
    group.alerts_threshold_up = 1
    assert !group.save()
    assert(group.errors.length == 1 && group.errors.include?(:alerts_threshold_down))
    
    # test alerts_email not an email address
    group.alerts_threshold_down = '1'
    group.alerts_email = 'no email address here'
    assert !group.save()
    assert(group.errors.length == 1 && group.errors.include?(:alerts_email))
    
    # test custom validation (no empty fields if alerts is true)
    group.alerts_threshold_up = ''
    group.alerts_email = ''
    assert !group.save()
    assert(group.errors.length == 2 && group.errors.include?(:alerts_email) && group.errors.include?(:alerts_threshold_up))
    
    group.alerts_threshold_up = 1
    group.alerts_email = 'test@test.com'
    assert group.save()
    
    group.alerts_email = 'test@test.com,WRONG!'
    assert !group.save()
    assert_equal 1, group.errors.length
    assert group.errors.include?(:alerts_email)
    
    group.alerts_email = 'test@test.com,dev.test@bar2.com'
    assert group.save()
  end
  
  test "monitor!" do
    group = groups(:archived)
    # shouldn't save cos name is missing
    assert group.monitor == false, 'monitor attribute of archived group should be set to false in fixtures file'
    assert group.monitor!, 'should change from false to true'
    assert group.monitor, 'monitor attribute should have changed'
    group = Group.find(group.id)
    assert group.monitor, 'monitor attribute should be true'
    assert !group.monitor!, 'should change from true to false'
    assert group.monitor == false, 'monitor attribute should be false again'
  end
  
  test "count_stats!" do
    group = groups(:archived)
    # shouldn't save cos name is missing
    assert group.count_stats == false, 'monitor attribute of archived group should be set to false in fixtures file'
    assert group.count_stats!, 'should change from false to true'
    assert group.count_stats, 'monitor attribute should have changed'
    group = Group.find(group.id)
    assert group.count_stats, 'monitor attribute should be true'
    assert !group.count_stats!, 'should change from true to false'
    assert group.count_stats == false, 'monitor attribute should be false again'
  end
  
  test "group join_all_wisp" do
    groups = Group.all_join_wisp
    assert groups[0].attributes.include?('wisp_name')
    
    groups = Group.all_join_wisp("wisp_id = ? OR wisp_id IS NULL", [1])
    assert groups[0].attributes.include?('wisp_name')
    
    groups = Group.all_join_wisp("wisp_id = ?", [1])
    assert groups[0].attributes.include?('wisp_name')
    assert groups.length == 3
  end
  
  test "delete default group" do
    default_group = groups(:default)
    group_count = Group.count()
    default_group.destroy
    assert Group.count() == group_count, "should not be possible to delete default group"
  end
  
  test "Group all_accessible_to method" do
    assert_equal Group.all.count, Group.all_accessible_to(users(:admin)).length, "admin should see all the groups"
    assert_equal 3, Group.all_accessible_to(users(:brescia_admin)).length, "brescia_admin should see only 3 groups (2 general groups and 1 specific to his wisp)"
    assert_equal 0, Group.all_accessible_to(users(:sfigato)).length, "sfigato should not see any group"
    assert_equal 6, Group.all_accessible_to(users(:mixed_operator)).length, "mixed_operator should not see 6 groups (2 general groups, 1 for brescia and 2 for provincia)"
  end
end