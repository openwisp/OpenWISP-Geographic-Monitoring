class ConnectedClient
  attr_reader :last_activity, :mac_address

  def initialize(client)
    @last_activity = client['last_activity'].to_time
    @mac_address = client['mac_address']
  end

  def last_activity_short
    last_activity.to_s(:short)
  end

  def vendor
    macvendor = MacVendor.find_by_oui(mac_address[0..7])
    macvendor.nil? ? I18n.t(:Unknown) : macvendor.vendor
  end
end