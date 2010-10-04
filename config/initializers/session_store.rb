# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_owgm_session',
  :secret      => 'cc6c5f075097e1b337b6dd84f37ca58552c0a20401e63478811c82a874b0667935dfbabf623d374a242e216bc3cd9ff84b532aa5317a6f94e0082e4ac77bb9c3'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
