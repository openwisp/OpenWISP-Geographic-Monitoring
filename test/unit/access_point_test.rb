require 'test_helper'

class AccessPointTest < ActiveSupport::TestCase 
  test "batch_change_property" do
    # test group
    assert_not_equal 3, AccessPoint.find(1).properties.group_id
    assert_not_equal 3, AccessPoint.find(2).properties.group_id
    
    AccessPoint.batch_change_property([1, 2], 'group_id', 3)
    
    assert_equal 3, AccessPoint.find(1).properties.group_id
    assert_equal 3, AccessPoint.find(2).properties.group_id
    
    AccessPoint.find(3, 4).each do |ap|
      assert_not_equal 3, ap.properties.group_id
    end
    
    # test for public
    assert !AccessPoint.find(2).properties.public
    assert !AccessPoint.find(5).properties.public
    assert !AccessPoint.find(6).properties.public
    
    AccessPoint.batch_change_property([2, 5, 6], 'public', true)
    assert AccessPoint.find(2).properties.public
    assert AccessPoint.find(5).properties.public
    assert AccessPoint.find(6).properties.public
    
    AccessPoint.batch_change_property([2, 5, 6], 'public', false)
    assert !AccessPoint.find(2).properties.public
    assert !AccessPoint.find(5).properties.public
    assert !AccessPoint.find(6).properties.public
    
    # test for favourite
    assert !AccessPoint.find(2).properties.favourite?
    assert !AccessPoint.find(5).properties.favourite?
    assert !AccessPoint.find(6).properties.favourite?
    
    AccessPoint.batch_change_property([2, 5, 6], 'favourite', true)
    assert AccessPoint.find(2).properties.favourite
    assert AccessPoint.find(5).properties.favourite
    assert AccessPoint.find(6).properties.favourite
    
    AccessPoint.batch_change_property([2, 5, 6], 'favourite', false)
    assert !AccessPoint.find(2).properties.favourite
    assert !AccessPoint.find(5).properties.favourite
    assert !AccessPoint.find(6).properties.favourite
  end
  
  test "build_all_properties" do
    AccessPoint.build_all_properties()
    # ensure all group names are present
    AccessPoint.with_properties_and_group.each do |ap|
      assert_not_nil ap.group_name
    end
  end
  
  test "ensure_with_properties_and_group" do
    ap = AccessPoint.last
    exception = assert_raises(RuntimeError) { ap.alerts? }
    assert_equal "feature in use requires access points to be retrieved with AccessPoint.with_properties_and_group()", exception.message
  end
  
  test "alerts?" do
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    
    # alerts initially disabled
    assert ap.alerts? == false
    
    # enable alerts for AP  
    properties = ap.properties
    properties.alerts = true
    properties.manager_email = 'owner@test.com'
    properties.alerts_threshold_up = 20
    properties.alerts_threshold_down = 10
    assert properties.save
    
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    assert ap.alerts? == true
    
    # disable alerts for AP but enable for group
    properties.alerts = false
    properties.save
    group = Group.find(properties.group_id)
    group.alerts = true
    group.alerts_threshold_up = 1
    group.alerts_threshold_down = 1
    group.alerts_email = 'test@test.com'
    group.save
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    assert ap.alerts? == true
    
    group.alerts = false
    group.save
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    assert ap.alerts? == false
  end
  
  test "manager email validation" do
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    
    # enable alerts for AP  
    properties = ap.properties
    properties.alerts = true
    properties.manager_email = 'owner@test.com'
    properties.alerts_threshold_up = 20
    properties.alerts_threshold_down = 10
    assert properties.save
    
    # ensure mail address gets validated
    properties.manager_email = 'not an email'
    assert !properties.save
    assert(properties.errors.length == 1 && properties.errors.include?(:manager_email))
    
    # 1 email address only
    properties.manager_email = 'two@email.com,addresses@email.com'
    assert !properties.save
    assert(properties.errors.length == 1 && properties.errors.include?(:manager_email))
  end
  
  test "threshold" do
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    
    group = Group.find(ap.group_id)
    group.alerts = true
    group.alerts_threshold_up = 2
    group.alerts_threshold_down = 1
    group.alerts_email = 'test@test.com'
    group.save
    
    # threshold_down is 1 and taken from group
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    assert_equal 2, ap.threshold_up.to_i
    assert_equal 1, ap.threshold_down.to_i
    
    # access point overrides threshold settings
    ap.properties.alerts = true
    ap.properties.manager_email = 'owner@test.com'
    ap.properties.alerts_threshold_up = 20
    ap.properties.alerts_threshold_down = 10
    ap.properties.save
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    assert_equal 20, ap.threshold_up.to_i
    assert_equal 10, ap.threshold_down.to_i
    
    # ensure positive integer
    ap.properties.alerts_threshold_up = -1
    assert !ap.properties.save
    assert(ap.properties.errors.length == 1 && ap.properties.errors.include?(:alerts_threshold_up))
    
    # ensure positive integer
    ap.properties.alerts_threshold_up = 0
    ap.properties.alerts_threshold_down = -1
    assert !ap.properties.save
    assert(ap.properties.errors.length == 1 && ap.properties.errors.include?(:alerts_threshold_down))
  end
  
  test "reset alert settings" do
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    
    assert !ap.alerts? 
    
    ap.properties.alerts = true
    ap.properties.manager_email = 'owner@test.com'
    ap.properties.alerts_threshold_up = 20
    ap.properties.alerts_threshold_down = 10
    ap.properties.save
    
    # retrieve again from DB
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    assert ap.alerts?
    
    ap.reset_alert_settings()
    
    # retrieve again from DB
    ap = AccessPoint.with_properties_and_group.sort_with('id', 'asc')[0]
    assert_nil ap.properties.alerts
    assert_nil ap.properties.alerts_threshold_up
    assert_nil ap.properties.alerts_threshold_down
  end
  
  test "self_favourite" do
    # all wisps
    assert_equal 1, AccessPoint.favourite.count
    assert_equal 1, AccessPoint.favourite(:up).count
    assert_equal 0, AccessPoint.favourite(:down).count
    assert_equal 1, AccessPoint.favourite(:known).count
    assert_equal 0, AccessPoint.favourite(:unknown).count
    
    # wisp 1
    assert_equal 1, AccessPoint.favourite(:total, 1).count
    assert_equal 1, AccessPoint.favourite(:up, 1).count
    assert_equal 0, AccessPoint.favourite(:down, 1).count
    assert_equal 1, AccessPoint.favourite(:known, 1).count
    assert_equal 0, AccessPoint.favourite(:unknown, 1).count
    
    # wisp 2
    assert_equal 0, AccessPoint.favourite(:total, 2).count
    assert_equal 0, AccessPoint.favourite(:up, 2).count
    assert_equal 0, AccessPoint.favourite(:down, 2).count
    assert_equal 0, AccessPoint.favourite(:known, 2).count
    assert_equal 0, AccessPoint.favourite(:unknown, 2).count
    
    assert_raise ArgumentError do
      AccessPoint.favourite(:wrong_parameter)
    end
  end
  
  test "test count methods" do
    assert_equal 4, AccessPoint.total.count
    assert_equal 1, AccessPoint.up.count
    assert_equal 1, AccessPoint.down.count
    assert_equal 2, AccessPoint.unknown.count
    assert_equal 2, AccessPoint.known.count
  end
  
  test "get_status_changes_between_dates" do
    def do_test(ap)
      ap.activities.destroy_all()
      ap.reachable!
      date_range = DateTime.now-2.hours..DateTime.now+2.hours
      
      # initial is 0 because no changed in the specified datetime range
      assert_equal 0, ap.get_status_changes_between_dates(date_range)
      
      # expect 0
      ap.activities.build(:status => true).save!
      assert_equal 0, ap.get_status_changes_between_dates(date_range)
      
      # expect 1 status change
      ap.activities.build(:status => false).save!
      ap.unreachable!
      assert_equal 1, ap.get_status_changes_between_dates(date_range)
      
      # expect again 1 only cos status hasn't changed
      ap.activities.build(:status => false).save!
      assert_equal 1, ap.get_status_changes_between_dates(date_range)
      
      # now we should have 2
      ap.activities.build(:status => true).save!
      ap.reachable!
      assert_equal 2, ap.get_status_changes_between_dates(date_range)
      
      # then 3
      ap.activities.build(:status => false).save!
      ap.unreachable!
      assert_equal 3, ap.get_status_changes_between_dates(date_range)
      
      # now 4
      ap.activities.build(:status => true).save!
      ap.reachable!
      assert_equal 4, ap.get_status_changes_between_dates(date_range)
      
      # stays 4 cos status hasn't changed
      ap.activities.build(:status => true).save!
      assert_equal 4, ap.get_status_changes_between_dates(date_range)
      ap.activities.build(:status => true).save!
      assert_equal 4, ap.get_status_changes_between_dates(date_range)
    end
    
    do_test(AccessPoint.first)
    
    ap = AccessPoint.with_properties_and_group("access_points.*, property_sets.reachable, property_sets.public, property_sets.site_description,
      property_sets.category, property_sets.group_id, property_sets.notes, groups.monitor AS group_monitor").first
    do_test(ap)
  end
  
  test "sorting" do
    
    def test_sorting(attr='id', direction='asc')
      prev = nil
    
      AccessPoint.with_properties_and_group.sort_with(attr, direction).each do |ap|
        unless prev.nil? or ap[attr].nil?
          # current value must be greater
          if direction == 'asc'
            # it must be higher or at least the same (not less)
            assert((ap[attr] > prev or ap[attr] == prev))
          else
            # it must be less or at least the same (not higher)
            assert((ap[attr] < prev or ap[attr] == prev))
          end
        else
          # assign previous
          prev = ap[attr]
        end
      end
    end
    
    test_sorting()
    test_sorting('id', 'desc')
    test_sorting('hostname', 'asc')
    test_sorting('hostname', 'desc')
    test_sorting('site_description', 'asc')
    test_sorting('site_description', 'desc')
    test_sorting('address', 'asc')
    test_sorting('address', 'desc')
    test_sorting('city', 'asc')
    test_sorting('city', 'desc')
    test_sorting('mac_address', 'asc')
    test_sorting('mac_address', 'desc')
    test_sorting('ip_address', 'asc')
    test_sorting('ip_address', 'desc')
    test_sorting('activation_date', 'asc')
    test_sorting('activation_date', 'desc')
    test_sorting('group', 'asc')
    test_sorting('group', 'desc')
    test_sorting('public', 'asc')
    test_sorting('public', 'desc')
    test_sorting('favourite', 'asc')
    test_sorting('favourite', 'desc')
  end
end
