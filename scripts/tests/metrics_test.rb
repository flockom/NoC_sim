# metrics_test.rb
# Author: Frank Lockom
# tests for metrics.rb functions

require 'test/unit'
require_relative '../metrics.rb'
require_relative '../driver.rb'
require_relative '../scrape.rb'

class MetricsTest < Test::Unit::TestCase
  def test_hop_count_XY
    # some base cases
    assert_equal(0,hop_count_XY(0,0,1))
    assert_equal(0,hop_count_XY(0,0,4))
    
    # x only
    assert_equal(1,hop_count_XY(0,1,4))
    assert_equal(3,hop_count_XY(0,3,4))
    
    #y only
    assert_equal(1,hop_count_XY(0,4,4))
    assert_equal(2,hop_count_XY(0,8,4))

    #xy
    assert_equal(3,hop_count_XY(0,6,4))

    #rectangular mesh
    assert_equal(2,hop_count_XY(0,6,3))
    assert_equal(5,hop_count_XY(0,11,3))
  end
  
  def test_traffic_flow_occupancy
    #load up task graph test1
    tg1 = read_TG('./task-graphs/test_tfo1')
    assert_equal(0,a = traffic_flow_occupancy(tg1,{},0,0,4))
    assert_equal(5,a = traffic_flow_occupancy(tg1,{},0,1,4))
  end
end
