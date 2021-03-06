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
    # load up task graph test1
    tg1 = read_TG('./task-graphs/test_tfo1')
    # test with default mapping
    assert_equal(0,a = traffic_flow_occupancy(tg1,{},0,0,4))
    assert_equal(5,a = traffic_flow_occupancy(tg1,{},0,1,4))
    assert_equal(4,a = traffic_flow_occupancy(tg1,{},0,8,4))
    assert_equal(12,a = traffic_flow_occupancy(tg1,{},0,10,4))
    
    # test some replacement mappings
    assert_equal(0,a = traffic_flow_occupancy(tg1,{0=>2},0,0,4))
    # 2hops*5volume = 10
    assert_equal(10,a = traffic_flow_occupancy(tg1,{0=>3},0,1,4))
    # 4hops*2volume = 8
    assert_equal(8,a = traffic_flow_occupancy(tg1,{0=>2},0,8,4))
  end

  def test_avg_traffic_flow_occupancy
    # load up task graph test1
    tg1 = read_TG('./task-graphs/test_tfo1')
    #test with default mapping 5+4+12/3
    assert_equal((5+4+12)/3.0,avg_traffic_flow_occupancy(tg1,{},4))
    #test with core 0 mapped to core 2
    assert_equal((5+8+6)/3.0,avg_traffic_flow_occupancy(tg1,{0=>2},4))
  end

  def test_normalized_avg_tfo_delta
    # load up task graph test1
    tg1 = read_TG('./task-graphs/test_tfo1')

    assert_equal(0,normalized_avg_tfo_delta(tg1,{},4))
    assert_equal(10/21.0,normalized_avg_tfo_delta(tg1,{0=>2},4))
  end

  def test_tfo_delta_variance
    # load up task graph test1
    tg1 = read_TG('./task-graphs/test_tfo1')
    
    assert_equal(0,tfo_delta_variance(tg1,{},4))
    assert_equal(Math.sqrt(((0/7-10/21)**2+(4/7-10/21)**2+(6/7-10/21)**2)/3),tfo_delta_variance(tg1,{},4))
  end

  def test_total_tfo
    # load up task graph test1
    tg1 = read_TG('./task-graphs/test_tfo1')

    assert_equal(5+4+12,total_tfo(tg1,{},0,4))
    assert_equal(5+8+6,total_tfo(tg1,{0=>2},0,4))
    assert_equal(12,total_tfo(tg1,{},10,4))
    
    tg2 = read_TG('./task-graphs/test_tfototal')
    assert_equal(13,total_tfo(tg2,{},2,4))
  end
end
