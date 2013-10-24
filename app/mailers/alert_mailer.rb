class AlertMailer < ActionMailer::Base
  default :from => CONFIG['from_email']
  
  def notification(alert, ap)
    @alert = alert
    @ap = ap
    @admin = true
    
    if @alert.action == 'down'
      subject_text = I18n.t(:hostname_is_no_longer_reachable, :hostname => @ap.hostname)
    elsif @alert.action. == 'up'
      subject_text = I18n.t(:hostname_is_now_reachable_again, :hostname => @ap.hostname)
    end
    
    subject = "[OWGM] #{subject_text}"
    
    # send mail to admins
    mail(:to => @ap.group_alerts_email, :subject => subject)
    
    # send mail to AP manager
    if @ap.alerts and not @ap.manager_email.nil?
      @admin = false
      mail(:to => @ap.manager_email, :subject => subject)
    end
  end
end
