AppConfig.configure(:model => Configuration, :key => 'key')

begin
  AppConfig.load
rescue Exception
  puts 'Disabling AppConfig because of bad Configuration schema...'
end
