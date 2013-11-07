class AlertMailer < ActionMailer::Base
  default :from => CONFIG['from_email']
  
  add_template_helper(ApplicationHelper)
  
  def notification(alert, ap, email_address, admin=true)
    @alert = alert
    @ap = ap
    @admin = admin
    
    if @alert.action == 'down'
      subject_text = I18n.t(:hostname_is_no_longer_reachable, :hostname => @ap.hostname)
    elsif @alert.action. == 'up'
      subject_text = I18n.t(:hostname_is_now_reachable_again, :hostname => @ap.hostname)
    end
    
    subject = "[OWGM] #{subject_text}"
    
    # send mail
    mail(:to => email_address, :subject => subject)
  end
end