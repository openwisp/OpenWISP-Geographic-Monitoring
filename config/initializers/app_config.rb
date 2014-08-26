begin
  AppConfig.configure(:model => Configuration, :key => 'key')
  AppConfig.load
rescue
  puts 'Disabling AppConfig because of bad Configuration schema...'
end

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
CONFIG['max_pings'] = CONFIG['max_pings'] || 5
CONFIG['housekeeping_interval'] = CONFIG['housekeeping_interval'] || 5
CONFIG['protocol'] = CONFIG['protocol'] || 'https'
CONFIG['host'] = CONFIG['host'] || 'change_me.com'
CONFIG['subdir'] = CONFIG['subdir'] || 'owgm'
CONFIG['from_email'] = CONFIG['from_email'] || 'owgm@localhost'
CONFIG['alerts_threshold_down'] = CONFIG['alerts_threshold_down'] || 90
CONFIG['alerts_threshold_up'] = CONFIG['alerts_threshold_up'] || 45
CONFIG['alerts_email'] = CONFIG['alerts_email'] || ""
CONFIG['mail_subject_prefix'] = CONFIG['mail_subject_prefix'] || '[OWGM]'
CONFIG['exception_notification_recipients'] = CONFIG['exception_notification_recipients'] || 'root@localhost'
CONFIG['check_monitoring_max_min'] = CONFIG['check_monitoring_max_min'] || 15
CONFIG['user_counts_graphs'] = CONFIG['user_counts_graphs'].nil? ? true : CONFIG['user_counts_graphs']
CONFIG['ap_stats_collapsed'] ||= CONFIG['ap_stats_collapsed'].nil? ? false : CONFIG['ap_stats_collapsed']

# set mailer host
Owgm::Application.config.action_mailer.default_url_options = { :host => CONFIG['host'] }
