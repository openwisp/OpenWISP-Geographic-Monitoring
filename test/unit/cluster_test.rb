require 'test_helper'

class ClusterTest < ActiveSupport::TestCase

  test "monitor?" do    
    clusters = AccessPoint.with_properties_and_group.draw_map()
    
    for cluster in clusters:
      unless cluster.nil?
        cluster.monitor?
      end
    end
  end
  
end
