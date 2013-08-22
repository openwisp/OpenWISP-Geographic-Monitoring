require File.expand_path('../boot', __FILE__)

require 'rails/all'

# If you have a Gemfile, require the gems listed there, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, Rails.env) if defined?(Bundler)

# in case config.yml does not exist load the default example file
begin
    CONFIG = YAML.load_file("config/config.yml")[Rails.env]
rescue Errno::ENOENT
    CONFIG = YAML.load_file("config/config.default.yml")[Rails.env]
end
# default value for pagination in case it has not been specified in config.yml
CONFIG['default_pagination'] = CONFIG['access_point_pagination'][0]['value']
# if a default value has been specified in config.yml use that one instead
CONFIG['access_point_pagination'].each do |item|
    if item['default'] === true
        CONFIG['default_pagination'] = item['value']
        break
    end
end
# default values if not defined
CONFIG['last_logins'] = CONFIG['last_logins'].nil? ? true : CONFIG['last_logins'];
CONFIG['max_threads'] = CONFIG['max_threads'] || 10
CONFIG['ping_timeout'] = CONFIG['ping_timeout'] || 5
CONFIG['housekeeping_interval'] = CONFIG['housekeeping_interval'] || 5

# Specify where to look for the wisps and access_points table
# data. Only one value can be enable at a time.
# Possible values:
# :table => true || :table => false
# :owm => true || :owm => false
#
# If :table is true, the migrations will build a
# real sql table (and data).
# If :owm is strue, the migrations will create
# a view from OWM's tables.
# If both are true, :owm is preferred.
DATA_FROM = {
    :table => false,
    :owm => true
}

module Owgm
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib #{config.root}/lib/modules)

    # Only load the plugins named here, in the order given (default is alphabetical).
    # :all can be used as a placeholder for all plugins not explicitly named.
    # config.plugins = [ :exception_notification, :ssl_requirement, :all ]

    # Activate observers that should always be running.
    # config.active_record.observers = :cacher, :garbage_collector, :forum_observer

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    config.time_zone = 'Rome'

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    config.i18n.default_locale = :it

    # JavaScript files you want as :defaults (application.js is always included).
    config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Configure the default encoding used in templates for Ruby 1.9.
    config.encoding = "utf-8"

    # Configure sensitive parameters which will be filtered from the log file.
    config.filter_parameters += [:password]

    config.action_mailer.default_url_options = { :host => 'localhost:3000' }
  end
end
