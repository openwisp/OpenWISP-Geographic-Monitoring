class MacVendor < ActiveRecord::Base
  def self.unknown?(mac_address)
    find_by_mac_address(mac_address).nil?
  end

  def self.get_oui(mac_address)
    if mac_address.scan(/:/).count == 5
      mac_address[0..7]
    else
      mac_address
    end
  end

  def self.find_by_mac_address(mac_address)
    find_by_oui get_oui(mac_address)
  end
end
