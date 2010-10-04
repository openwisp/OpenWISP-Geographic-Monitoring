VERSION = '1.0'
 
namespace :fluid960 do
  desc 'Install the CSS files and images in public/stylesheets/960'
  task :install => ['fluid960:add_or_replace_fluid']
 
  desc 'Update the CSS files and images in public/stylesheets/960 for this application'
  task :update => ['fluid960:add_or_replace_fluid']
 
  task :add_or_replace_fluid do
    require 'fileutils'
    dest = "#{RAILS_ROOT}/public/stylesheets/960"
    if File.exists?(dest)
      # upgrade
      begin
        puts "Removing directory #{dest}..."
        FileUtils.rm_rf dest
        puts "Recreating directory #{dest}..."
        FileUtils.mkdir_p dest
        puts "Installing Fluid-960 version #{VERSION} to #{dest}..."
        FileUtils.cp_r "#{RAILS_ROOT}/vendor/plugins/fluid-960/public/stylesheets/960/.", dest
        puts "Successfully updated Fluid-960 to version #{VERSION}."
      rescue
        puts "ERROR: Problem updating Fluid-960. Please manually copy "
        puts "#{RAILS_ROOT}/vendor/plugins/fluid-960/public/stylesheets/960/."
        puts "to"
        puts "#{dest}"
      end
    else
      # install
      begin
        puts "Creating directory #{dest}..."
        FileUtils.mkdir_p dest
        puts "Installing Fluid-960 version #{VERSION} to #{dest}..."
        FileUtils.cp_r "#{RAILS_ROOT}/vendor/plugins/fluid-960/public/stylesheets/960/.", dest
        puts "Successfully installed Fluid-960 version #{VERSION}."
      rescue
        puts "ERROR: Problem installing Fluid-960. Please manually copy "
        puts "#{RAILS_ROOT}/vendor/plugins/fluid-960/public/stylesheets/960/."
        puts "to"
        puts "#{dest}"
      end
    end
  end
end