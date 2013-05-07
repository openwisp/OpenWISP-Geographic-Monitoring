ENV["RAILS_ENV"] = "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

module WispRolesFormula
  def expected_roles_count
    # expected roles forumla explained:
    # ([ALL_ROLES_COUNT] - [:wisps_viewer]) * [ALL_WISP_COUNT] + [:wisp_viewer]
    expected_roles_count = (User.available_roles.length - 1) * Wisp.all.count + 1
  end
end

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...
  include WispRolesFormula
end

class ActionController::TestCase
  include Devise::TestHelpers
  include WispRolesFormula
  include Rails.application.routes.url_helpers
  default_url_options[:host] = "test.host"
end
