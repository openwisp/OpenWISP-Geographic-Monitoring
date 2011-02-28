class Cluster
  def initialize(hotspots)
    if hotspots.is_a?(Array) && hotspots.all? {|hotspot| hotspot.is_a?(Hotspot)}
      @hotspots = hotspots
    else 
      raise "Cluster must be an Array of Hotspot models"
    end
  end

  def size
    @hotspots.count
  end

  def hotspots
    @hotspots
  end

  def lat
    @hotspots.inject(0.0) {|sum, hotspot| sum + hotspot.lat} / size
  end

  def lng
    @hotspots.inject(0.0) {|sum, hotspot| sum + hotspot.lng} / size
  end

  def status
    up = @hotspots.find_all{|hotspot| hotspot.up?}.count
    down = @hotspots.find_all{|hotspot| hotspot.down?}.count
    unknown = @hotspots.find_all{|hotspot| hotspot.unknown?}.count

    if down >= up && down >= unknown
      0
    elsif up > down && up >= unknown
      1
    elsif unknown > up && unknown > down
      -1
    end
  end

  def up?
    status == 1
  end

  def down?
    status == 0
  end

  def unknown?
    status == -1
  end
end
