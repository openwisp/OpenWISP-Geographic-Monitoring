Rake::Task["db:seed"].enhance do
  Rake::Task["mac_vendors:update"].invoke
end

namespace :mac_vendors do
  desc "Fetch oui <-> manufacturer association file from http://standards.ieee.org/develop/regauth/oui/oui.txt"
  task :update => :environment do
    require 'open-uri'

    puts "Updating ouis from http://standards.ieee.org/develop/regauth/oui/oui.txt"
    MacVendor.destroy_all
    open('http://standards.ieee.org/develop/regauth/oui/oui.txt').each do |line|
      match = line.match(/([0123456789ABCDEF]{2}-[0123456789ABCDEF]{2}-[0123456789ABCDEF]{2})\s+\(hex\)\s+(.*$)/)

      if match
        oui = match[1].gsub(/-/, ':')
        vendor = match[2]

        MacVendor.create! :vendor => vendor, :oui => oui
      end
    end
  end
end
