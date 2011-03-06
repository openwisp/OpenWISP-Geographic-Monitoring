module Addons
  module Mappable
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
        [(max_lat + min_lat)/2, (max_lon + min_lon)/2, (22 - (Math::log(max_distance * 2000))).to_i]
      else
        [(max_lat + min_lat)/2, (max_lon + min_lon)/2, 22]
      end
    end
  end
end


