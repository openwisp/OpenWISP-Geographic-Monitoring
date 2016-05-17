def log_exception(e)
  # exception notifier
  if CONFIG['exception_notifier_enabled']
    ExceptionNotifier::Notifier.background_exception_notification(e).deliver
  end
  # sentry
  if CONFIG['sentry_enabled']
    Raven.capture_exception(e)
  end
end
