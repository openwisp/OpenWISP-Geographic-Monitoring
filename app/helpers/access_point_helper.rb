module AccessPointHelper
  def image_path_for(marker)
    image = ''

    if marker.is_a? AccessPoint
      image = 'ap_'
    elsif marker.is_a? Cluster
      image = 'cluster_'
    end

    if marker.up?
      image += 'up.png'
    elsif marker.down?
      image += 'down.png'
    elsif marker.unknown?
      image += 'unknown.png'
    end

    image_path(image)
  end

  def image_tag_for(marker, opts={})
    image_tag image_path_for(marker), opts
  end
end
