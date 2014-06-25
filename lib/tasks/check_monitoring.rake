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
  
  task :false_negatives => :environment do
    include Rails.application.routes.url_helpers
    
    WISP = ENV['wisp']
    DEBUG = ENV['verbosity'].nil? ? true : false
    
    # if WISP argument is a number try to find by ID
    if WISP.to_i != 0
      wisp = Wisp.find(WISP)
    # otherwise use find_by_name
    else
      wisp = Wisp.find_by_name(WISP)
    end
    
    if not wisp.owmw_enabled?
      puts "Wisp does not have owmw enabled"
      return
    end
    
    access_points = wisp.access_points.with_properties_and_group.where('property_sets.reachable = 0 AND groups.count_stats = 1')
    RadiusSession.active_resource_from(wisp.owmw_url, wisp.owmw_username, wisp.owmw_password)
    
    possible_false_negatives = []
    counter = 0
    length = access_points.length
    
    access_points.each do |ap|
        if DEBUG
            counter = counter+1
            puts "#{counter} out of #{length}"
        end
        
        # retrieve radius sessions
        sessions = RadiusSession.find(:all, :params => { :mac_address => ap.common_name, :last => 1 })
        
        # if no radius sessions available skip to next iteration
        if sessions.length == 0
            next
        end
        
        unless sessions[0].acct_stop_time.nil?
            # get logout date
            date = Date.parse(sessions[0].acct_stop_time)
        else
            # user still logged in
            date = Date.today
        end
        
        # if date is today there is probability that is a false positive
        if date.today?
            possible_false_negatives.push(ap)
            if DEBUG
                puts "found possible false negative: #{ap.hostname}"
            end
        end
    end
    
    puts "\n\nPossible false negatives:\n\n"
    
    possible_false_negatives.each do |ap|
        puts "#{ap.hostname}: #{wisp_access_point_path(wisp, ap)}"
    end
    
    puts "\n\n"
  end
end