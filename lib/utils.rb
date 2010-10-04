module Utils

  def get_center_zoom(mappables)
    max_lat = max_lon = 0.0
    min_lat = min_lon = 360.0

    mappables.each do |m|
      lat = m.send(m.class.lat_column_name).to_f
      lon = m.send(m.class.lng_column_name).to_f

      if lat > max_lat
        max_lat =  lat
      end
      if lat < min_lat
        min_lat = lat
      end

      if lon > max_lon
        max_lon =  lon
      end
      if lon < min_lon
        min_lon = lon
      end
    end

    max_distance = (max_lat - min_lat) > (max_lon - min_lon) ? (max_lat - min_lat) : (max_lon - min_lon)
    if max_distance > 0
      [(max_lat + min_lat)/2, (max_lon + min_lon)/2, (16 - (Math::log(max_distance * 2000))).to_i]
    else
      [(max_lat + min_lat)/2, (max_lon + min_lon)/2, 16]
    end
  end


  # Extend GMap plugin to add keyboard
  # shortcuts to maps
  class Ym4r::GmPlugin::GMap
    def keboard_init
      self.record_init "
      new GKeyboardHandler(map);
      mapContainer = document.getElementById('#{self.container}');
      GEvent.trigger(document, 'click', {srcElement: mapContainer, target: mapContainer, nodeType: 1});
      "
    end

    def static_map_init()
      self.record_init "
      map.disableDragging();
      "
    end
  end
end


