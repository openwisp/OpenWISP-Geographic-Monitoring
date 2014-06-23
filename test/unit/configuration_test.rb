require 'test_helper'

class ConfigurationTest < ActiveSupport::TestCase
  test "get" do
    c = Configuration.get('wisps_with_owmw')
    assert_equal Array, c.class
    assert_equal 0, c.length 
  end
  
  test "set" do
    Configuration.set('wisps_with_owmw', 'test1', 'array')
    c = Configuration.get('wisps_with_owmw')
    assert_equal Array, c.class
    assert_equal 1, c.length
    assert_equal 'test1', c[0]
    
    Configuration.set('wisps_with_owmw', 'test1, test2', 'array')
    c = Configuration.get('wisps_with_owmw')
    assert_equal Array, c.class
    assert_equal 2, c.length
    assert_equal 'test1', c[0]
    assert_equal 'test2', c[1]
    
    Configuration.set('wisps_with_owmw', 'one,two,three', 'array')
    c = Configuration.get('wisps_with_owmw')
    assert_equal Array, c.class
    assert_equal 3, c.length
    assert_equal 'one', c[0]
    assert_equal 'two', c[1]
    assert_equal 'three', c[2]
  end
  
  test "slugify" do
    Configuration.set('wisps_with_owmw', 'Test Slug, Another One,Do It', 'array')
    c = Configuration.get('wisps_with_owmw')
    assert_equal c.class, Array
    assert_equal c.length, 3
    assert_equal 'test-slug', c[0]
    assert_equal 'another-one', c[1]
    assert_equal 'do-it', c[2]
  end
end
