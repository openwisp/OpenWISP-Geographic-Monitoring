namespace :fusion_charts do
  task :dir_setup do
    Dir.mkdir("#{RAILS_ROOT}/public/charts", 0700)
    puts "Created charts directory in public/"
  end

  task :cp_charts do
    FileUtils.cp_r("#{RAILS_ROOT}/vendor/plugins/fusioncharts/public/charts/", "#{RAILS_ROOT}/public/")
    puts "Charts copied."
  end

  task :cp_javascript do
    FileUtils.cp_r("#{RAILS_ROOT}/vendor/plugins/fusioncharts/public/javascripts/FusionCharts.js", "#{RAILS_ROOT}/public/javascripts/")
    puts "FusionCharts.js copied"
  end

  desc "Copies and creates all necessary files for FusionCharts"
  task :setup => [:dir_setup, :cp_charts, :cp_javascript]
end
