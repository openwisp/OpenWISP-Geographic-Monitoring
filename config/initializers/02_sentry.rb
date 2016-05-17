CONFIG['sentry_enabled'] = false

if CONFIG['sentry_dsn']
  Raven.configure do |config|
    config.dsn = CONFIG['sentry_dsn']
  end
  CONFIG['sentry_enabled'] = true
end
