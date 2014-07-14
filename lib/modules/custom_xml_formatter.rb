class CustomXMLFormatter
  # avoid NoMethodError: undefined method `collect!' for Hash
  # required for ruby 1.8.7 only
  # suggested here:
  # https://github.com/rails/rails/issues/2318#issuecomment-3555973
  include ActiveResource::Formats::XmlFormat

  def decode(xml)
    elements = ActiveResource::Formats::XmlFormat.decode(xml)['radius_accounting']
    return elements.is_a?(Hash) ? [elements] : elements
  end
end