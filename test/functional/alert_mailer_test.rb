require 'test_helper'

class AlertMailerTest < ActionMailer::TestCase
  test "notification" do
    I18n.default_locale = :en

    # enable alerts for AP and ensure no alerts are present in DB
    ap = AccessPoint.with_properties_and_group.find(1)
    ap.group.alerts = true
    ap.group.alerts_email = 'group@test.com,group2@test.com'
    ap.group.alerts_threshold_down = 0
    ap.group.alerts_threshold_up = 0
    ap.group.save!
    assert_equal 0, Alert.count

    ap.properties.manager_email = 'manager@test.com'
    ap.properties.save!

    # create alert and send
    ap.unreachable!
    assert_equal 1, Alert.count

    Alert.send_all

    assert !ActionMailer::Base.deliveries.empty?
    assert_equal 2, ActionMailer::Base.deliveries.length

    assert ActionMailer::Base.deliveries[0].subject.include?('wherecamp is no longer reachable')

    # send up mail
    ap.properties.manager_email = nil
    ap.properties.save!
    ap.reachable!

    Alert.send_all

    assert_equal 3, ActionMailer::Base.deliveries.length
    assert ActionMailer::Base.deliveries[2].subject.include?('wherecamp is now reachable again')
  end

  test "notification_customized" do
    I18n.default_locale = :en

    # enable alerts for AP and ensure no alerts are present in DB
    ap = AccessPoint.with_properties_and_group.find(1)
    ap.group.alerts = true
    ap.group.alerts_email = 'group@test.com'
    ap.group.alerts_threshold_down = 0
    ap.group.alerts_threshold_up = 0
    ap.group.save!

    CONFIG['alert_down_subject_suffix'] = "%{hostname} is DOWN"

    ap.unreachable!
    Alert.send_all

    CONFIG['alert_down_subject_suffix'] = nil

    assert_equal 1, ActionMailer::Base.deliveries.length
    assert ActionMailer::Base.deliveries[0].subject.include?('wherecamp is DOWN')

    CONFIG['alert_up_subject_suffix'] = "%{hostname} is UP"

    ap.reachable!
    Alert.send_all

    CONFIG['alert_up_subject_suffix'] = nil

    assert_equal 2, ActionMailer::Base.deliveries.length
    assert ActionMailer::Base.deliveries[1].subject.include?('wherecamp is UP')
  end
end
