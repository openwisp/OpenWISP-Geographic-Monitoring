# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).


# Create configurations key:value needed to run OWGM
puts 'Creating necessary configuration keys'
Configuration.set(
    :owmw_enabled,
    false,
    :boolean,
    "This configuration enables/disables interaction with the OWMW middleware"
)

Configuration.set(
    :wisps_with_owmw,
    [],
    :array,
    "This configuration enables/disables interaction with the OWMW middleware for specific wisps"
)



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