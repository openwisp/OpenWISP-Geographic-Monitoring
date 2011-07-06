class Cluster
  def initialize(access_points)
    if access_points.is_a?(Array) && access_points.all? {|access_point| access_point.is_a?(AccessPoint)}
      @access_points = access_points
    else 
      raise "Cluster must be an Array of AccessPoint models"
    end
  end

  def size
    @access_points.count
  end

  def access_points
    @access_points
  end

  def lat
    @access_points.inject(0.0) {|sum, access_point| sum + access_point.lat} / size
  end

  def lng
    @access_points.inject(0.0) {|sum, access_point| sum + access_point.lng} / size
  end

  def status
    up = @access_points.find_all{|access_point| access_point.up?}.count
    down = @access_points.find_all{|access_point| access_point.down?}.count
    unknown = @access_points.find_all{|access_point| access_point.unknown?}.count

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
