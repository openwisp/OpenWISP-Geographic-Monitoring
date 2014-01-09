require 'test_helper'

class AlertMailerTest < ActionMailer::TestCase
  # replace this with your real tests
  test "notification" do
    
    # enable alerts for AP and ensure no alerts are present in DB
    ap = AccessPoint.with_properties_and_group.find(1)
    ap.group.alerts = true
    ap.group.alerts_email = 'group@test.com,group2@test.com'
    ap.group.alerts_threshold_down = 0
    ap.group.alerts_threshold_up = 0
    ap.group.save!
    assert_equal 0, Alert.count
    
    ap.manager_email = 'manager@test.com'
    
    # create alert and send
    ap.unreachable!
    assert_equal 1, Alert.count
    
    alert = Alert.last
    alert.send_email()
    
    assert !ActionMailer::Base.deliveries.empty?
    assert ActionMailer::Base.deliveries.length, 2
  end
end
