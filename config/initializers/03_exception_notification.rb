CONFIG['exception_notifier_enabled'] = false

if Rails.env.production? and CONFIG['sentry_dsn'].nil? and CONFIG['exception_notification_recipients']
  ExceptionNotifier::Notifier.prepend_view_path File.join(Rails.root, 'app/views')

  recipients = CONFIG['exception_notification_recipients'].split(',') rescue false
  sender = CONFIG['from_email']
  email_subject_prefix = CONFIG['mail_subject_prefix']

  if recipients
    Owgm::Application.config.middleware.use(
      ExceptionNotifier,
      :email_prefix => email_subject_prefix << ' ',
      :sender_address => sender,
      :exception_recipients => recipients,
      :sections =>  %w(request session devise environment backtrace)
    )
    CONFIG['exception_notifier_enabled'] = true
  end
end
