namespace :daemons do
  desc "Start deamons required to run OWGM"
  task :start => :environment do
    puts 'Starting BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb start]

    Rake::Task['daemons:status'].execute
  end

  desc "Stop deamons required to run OWGM"
  task :stop => :environment do
    puts 'Stopping BackgrounDRb...'
    %x[bundle exec #{Rails.root}/script/backgroundrb stop]

    Rake::Task['daemons:status'].execute
  end

  desc "Restart deamons required to run OWGM"
  task :restart => :environment do
    puts 'Restarting OWGM daemons...'
    Rake::Task['daemons:stop'].execute
    Rake::Task['daemons:start'].execute
  end

  desc "Status of daemons required to run OWGM"
  task :status => :environment do
    print 'BackgrounDRb: '
    %x[bundle exec #{Rails.root}/script/backgroundrb status]
    puts $? == 0 ? 'running...' : 'not running...'
  end
end
