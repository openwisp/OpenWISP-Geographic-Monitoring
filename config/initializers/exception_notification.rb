if Rails.env.production?
  ExceptionNotifier::Notifier.prepend_view_path File.join(Rails.root, 'app/views')

  recipients = CONFIG['exception_notification_recipients'].split(',')
  sender = CONFIG['from_email']
  email_subject_prefix = CONFIG['mail_subject_prefix']

  Owgm::Application.config.middleware.use(
    ExceptionNotifier,
    :email_prefix => email_subject_prefix << ' ',
    :sender_address => sender,
    :exception_recipients => recipients,
    :sections =>  %w(request session devise environment backtrace)
  )
end