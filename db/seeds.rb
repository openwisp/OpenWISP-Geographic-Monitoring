# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).

# Clean the User model
puts 'Emptying the User model with User.delete_all'
User.delete_all

# Create an admin user with every role contained in User::ROLES
puts 'Creating admin user with password admin'
admin = User.create(
    :username => "admin",
    :email => "admin@mail.it",
    :password => "admin",
    :password_confirmation => "admin"
)
puts 'Assigning every role in User::ROLES to the admin user'
User::ROLES.each{|role| admin.has_role! role}

# Add default configuration keys
puts 'Adding default configuration keys'
Configuration.set('owmw_site', 'http://owmw/site/access_points')
Configuration.set('owmw_user','admin')
Configuration.set('owmw_password','password')
