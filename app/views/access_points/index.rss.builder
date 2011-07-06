xml.instruct! :xml, :version=>"1.0"
xml.rss(:version => "2.0", "xmlns:georss" => "http://www.georss.org/georss") do
  xml.channel do
    xml.title("Provinciawifi GeoRSS feed")
    xml.link("http://www.caspur.it/")
    xml.author do
      xml.name("WiFi Team - CASPUR")
      xml.email("wifi@caspur.it")
    end
    xml.description("Provinciawifi Access Points")
    xml.language('en-us')
    for ap in @access_points
      xml.item do
        xml.title("Provinciawifi")
        xml.updated("#{ap.updated_at}")
        xml.summary("#{ap.hostname}")
        xml.description("#{ap.site_description} - #{ap.city}")
        xml.tag!("georss:point", ap.lat.to_s + ' ' + ap.lng.to_s)
      end
    end
  end
end