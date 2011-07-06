class AssociatedUser < ActiveResource::Base
  extend ActiveModel::Naming
  include ActiveModel::Serializers::Xml

  def self.active_resource_from(url, username, password)
    self.site = "#{url}/access_points/:access_point"
    self.user = username
    self.password = password
  end
end
