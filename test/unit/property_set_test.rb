require 'test_helper'

class PropertySetTest < ActiveSupport::TestCase
  test "find_orphans" do
    orphans = PropertySet.find_orphans()
    assert_equal 3, orphans.length
    # verify id
    i = 97
    orphans.each do |o|
      assert_equal i, o.access_point_id
      i += 1
    end
  end
  
  test "destroy_orphans" do   
    assert_difference('PropertySet.count', -3) do
      PropertySet.destroy_orphans()
    end
    orphans = PropertySet.find_orphans()
    assert_equal 0, orphans.length
  end
    
end
