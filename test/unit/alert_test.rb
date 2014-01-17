require 'test_helper'

class AlertTest < ActiveSupport::TestCase

  test "build" do    
    exception = assert_raises(ArgumentError) { Alert.build(:status => 'up') }
    assert_equal ":access_point_id parameter missing", exception.message
    
    exception = assert_raises(ArgumentError) { Alert.build(:access_point_id => 1) }
    assert_equal ":status parameter missing", exception.message
    
    assert_equal 0, Alert.count
    
    Alert.build(:access_point_id => 1, :status => true)
    
    assert_equal 1, Alert.where(:access_point_id => 1, :action => 'up', :sent => false).count
    assert_equal 1, Alert.count
    
    Alert.build(:access_point_id => 1, :status => false)
    
    assert_equal 1, Alert.count
    assert_equal 0, Alert.where(:access_point_id => 1, :action => 'up', :sent => false).count
    assert_equal 1, Alert.where(:access_point_id => 1, :action => 'down', :sent => false).count
    
    # deletes previous alert if not sent
    Alert.build(:access_point_id => 1, :status => false)
    assert_equal 1, Alert.count
    
    # send
    Alert.last.send_email()
    assert_equal 1, Alert.where(:access_point_id => 1, :action => 'down', :sent => true).count
    
    # should not create other alerts with same status (DOWN) consecutively for the same access point
    Alert.build(:access_point_id => 1, :status => false)
    assert_equal 1, Alert.count
    
    # should create a new alert
    Alert.build(:access_point_id => 1, :status => true)
    assert_equal 2, Alert.count
    
    # deletes previous alert if not sent
    Alert.build(:access_point_id => 1, :status => true)
    assert_equal 2, Alert.count
    
    # won't create alert at all
    Alert.build(:access_point_id => 1, :status => true)
    assert_equal 2, Alert.count
  end
  
  test "send_all" do
    assert_equal 0, Alert.send_all
    
    ap = AccessPoint.with_properties_and_group.find(1)
    ap.group.alerts = true
    ap.group.alerts_email = 'group@test.com'
    ap.group.alerts_threshold_down = 2
    ap.group.alerts_threshold_up = 1
    ap.group.save!
    
    ap = AccessPoint.with_properties_and_group.find(1)
    assert ap.alerts?
    assert_equal 0, Alert.count
    
    # here an alert should be created
    ap.reachable!
    assert_equal 1, Alert.where(:access_point_id => ap.id, :action => 'up', :sent => false).count
    assert_equal 1, Alert.count
    
    # try to send, but nothing will be sent cos threshold is not passed yet
    assert_equal 0, Alert.send_all
    assert_equal 1, Alert.where(:sent => false).count  # alert is still there
    
    # disable alerts
    ap.group.alerts = false
    ap.group.save!
    assert_equal 0, Alert.send_all
    # alert has been destroyed
    assert_equal 0, Alert.where(:sent => false).count
    assert_equal 0, Alert.count
    
    # re-enable alerts and create a new alert
    ap.group.alerts = true
    ap.group.save!
    ap.reachable!
    assert_equal 1, Alert.where(:access_point_id => ap.id, :action => 'up', :sent => false).count
    assert_equal 1, Alert.count
    # change alert creation date to a value higher than the threshold
    alert = Alert.first
    alert.created_at = DateTime.now.ago(3.minutes)
    alert.save!
    # try sending all ... now we expect 1 to be sent
    assert_equal 1, Alert.send_all
    # ensure alert is marked as sent
    alert = Alert.find(alert.id)
    assert alert.sent
    
    ap1 = ap
    ap2 = AccessPoint.with_properties_and_group.find(2)
    ap2.group.alerts = true
    ap2.group.alerts_email = 'group@test.com'
    ap2.group.alerts_threshold_down = 2
    ap2.group.alerts_threshold_up = 1
    ap2.group.save!
    
    # create more alerts for different APs
    ap1.unreachable!
    ap2.reachable!
    
    # change alert creation date to a value higher than the threshold
    Alert.where(:sent => false).each do |alert|
      alert.created_at = DateTime.now.ago(10.minutes)
      alert.save!
    end
    
    # try sending all ... now we expect 2 to be sent
    assert_equal 2, Alert.send_all
    
    # ensure all alerts are sent
    assert_equal 0, Alert.where(:sent => false).count
  end
end
