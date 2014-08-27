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
    assert ActionMailer::Base.deliveries[0].body.include?('Notification type: PROBLEM')
    assert ActionMailer::Base.deliveries[0].body.include?('URL:')

    # send up mail
    ap.properties.manager_email = nil
    ap.properties.save!
    ap.reachable!

    Alert.send_all

    assert_equal 3, ActionMailer::Base.deliveries.length
    assert ActionMailer::Base.deliveries[2].subject.include?('wherecamp is now reachable again')
    assert ActionMailer::Base.deliveries[2].body.include?('Notification type: RECOVERY')
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
    ap.properties.manager_email = 'manager@test.com'
    ap.properties.save!

    CONFIG['alert_down_subject_suffix'] = "%{hostname} is DOWN"
    CONFIG['alert_up_subject_suffix'] = "%{hostname} is UP"
    CONFIG['alert_body_text_admin'] = """Custom body text admin
***** OpenWISP Geographic Monitoring *****

Notification type: %{notification_type}
Host: %{hostname}
Status: %{status} since %{status_changed_at}

City: %{city}
Address: %{address}
Ip address: %{ip}
Mac address: %{mac_address}

Notes:
%{notes}

URL: %{url}"""
    CONFIG['alert_body_text_manager'] = """Custom body text manager
***** OpenWISP Geographic Monitoring *****

Notification type: %{notification_type}
Host: %{hostname}
Status: %{status} since %{status_changed_at}

City: %{city}
Address: %{address}
Ip address: %{ip}
Mac address: %{mac_address}

Notes:
%{notes}
"""

    ap.unreachable!
    Alert.send_all

    assert_equal 2, ActionMailer::Base.deliveries.length
    # admin email
    assert ActionMailer::Base.deliveries[0].subject.include?('wherecamp is DOWN')
    assert ActionMailer::Base.deliveries[0].body.include?('Notification type: PROBLEM')
    assert ActionMailer::Base.deliveries[0].body.include?('Custom body text admin')
    assert ActionMailer::Base.deliveries[0].body.include?('URL:')
    # manager email
    assert ActionMailer::Base.deliveries[1].subject.include?('wherecamp is DOWN')
    assert ActionMailer::Base.deliveries[1].body.include?('Notification type: PROBLEM')
    assert ActionMailer::Base.deliveries[1].body.include?('Custom body text manager')
    assert !ActionMailer::Base.deliveries[1].body.include?('URL:')

    ap.reachable!
    Alert.send_all

    assert_equal 4, ActionMailer::Base.deliveries.length
    assert ActionMailer::Base.deliveries[2].subject.include?('wherecamp is UP')
    assert ActionMailer::Base.deliveries[2].body.include?('Notification type: RECOVERY')
    assert ActionMailer::Base.deliveries[2].body.include?('Custom body text admin')

    CONFIG['alert_down_subject_suffix'] = nil
    CONFIG['alert_up_subject_suffix'] = nil
    CONFIG['alert_body_text_admin'] = nil
    CONFIG['alert_body_text_manager'] = nil
  end
end
