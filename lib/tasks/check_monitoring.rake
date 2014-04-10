namespace :check do
  desc "Ensure monitoring worker is doing its job"
  task :monitoring => :environment do
    number = CONFIG['check_monitoring_max_min']
    # if last ping is older than "check_monitoring_max_min"
    # send an email to admins
    if Activity.last.created_at < number.minutes.ago
      e = Exception.new('MONITORING NOT WORKING PROPERLY')
      ExceptionNotifier::Notifier.background_exception_notification(e).deliver
    end
  end
end