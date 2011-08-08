begin
  AppConfig.configure(:model => Configuration, :key => 'key')
  AppConfig.load
rescue
  puts 'Disabling AppConfig because of bad Configuration schema...'
end
