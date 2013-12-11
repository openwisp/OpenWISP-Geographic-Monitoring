if Rails.env.production?
  ExceptionNotifier::Notifier.prepend_view_path File.join(Rails.root, 'app/views')

  recipients = CONFIG['exception_notification_recipients'].split(',') rescue 'root@localhost'
  sender = CONFIG['from_email'] rescue 'root@localhost'
  email_subject_prefix = CONFIG['mail_subject_prefix'] rescue '[OWGM]'

  Owums::Application.config.middleware.use(
    ExceptionNotifier,
    :email_prefix => email_subject_prefix << ' ',
    :sender_address => sender,
    :exception_recipients => recipients,
    :sections =>  %w(request session devise environment backtrace)
  )
end
