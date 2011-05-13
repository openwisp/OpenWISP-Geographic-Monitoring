class OnlineUser < ActiveResource::Base
  extend ActiveModel::Naming
  include ActiveModel::Serializers::Xml

  self.site = "#{Configuration.get('owmw_site')}/:hotspot"
  self.user = Configuration.get('owmw_user')
  self.password = Configuration.get('owmw_password')
end
