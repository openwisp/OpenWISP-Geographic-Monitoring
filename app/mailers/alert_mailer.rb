class AlertMailer < ActionMailer::Base
  default :from => CONFIG['from_email']

  add_template_helper(ApplicationHelper)

  def notification(alert, ap, email_address, admin=true)
    @alert = alert
    @ap = ap
    @admin = admin

    if @alert.action == 'down'
      if CONFIG['alert_down_subject_suffix'].nil?
        subject_text = I18n.t(:hostname_is_no_longer_reachable, :hostname => @ap.hostname)
      else
        subject_text = CONFIG['alert_down_subject_suffix'] % { :hostname => @ap.hostname }
      end
    elsif @alert.action. == 'up'
      if CONFIG['alert_up_subject_suffix'].nil?
        subject_text = I18n.t(:hostname_is_now_reachable_again, :hostname => @ap.hostname)
      else
        subject_text = CONFIG['alert_up_subject_suffix'] % { :hostname => @ap.hostname }
      end
    end

    subject = "#{CONFIG['mail_subject_prefix']} #{subject_text}"

    # send mail
    mail(:to => email_address, :subject => subject)
  end
end
