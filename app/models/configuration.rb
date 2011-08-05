class Configuration < ActiveRecord::Base

  validates :key, :presence => true,
            :format => { :with => /\A[a-z_\.,]+\Z/ }
  validates :value_format, :presence => true

  def self.get(key)
    value = AppConfig[key]
    raise("BUG: value for key #{key} not found!") if value.nil?

    value
  end

  def self.set(key, value, format, description = nil)
    key = key.to_s
    value = value.to_s
    format = format.to_s

    #begin
      AppConfig.set_key(key, value, format)

      configuration = find_or_initialize_by_key(key)

      configuration.update_attributes!(
          :key => key,
          :value => value,
          :value_format => format,
          :description => description
      )
    #rescue
    #  raise("BUG: key #{key} could not be set!")
    #end
  end
end
