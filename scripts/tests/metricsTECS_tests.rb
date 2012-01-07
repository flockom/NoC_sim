# metricsTECS_test.rb
# Author: Frank Lockom
# tests for metricsTECS.rb functions


require 'test/unit'
require_relative '../metricsTECS.rb'
require_relative '../scrape.rb'


class MetricsTECSTest < Test::Unit::TestCase

  def test_build_adjacency_list
    # tg = random_mapping(generate_tg(1,7,7,7,20,10,20,10),4,3,right_col_redundant(4,3))
    tg = [
          [[4, 19], [5, 20], [9, 20], [8, 19], [0, 22], [10, 22], [6, 25], [1, 20]], 
          [[4, 5, 22], [5, 9, 22], [5, 8, 29], [5, 0, 29], [5, 10, 20], [8, 6, 25], [9, 1, 22]]
         ]
    
    tg_adj = build_adjacency_list(tg)

    [[4, 19], [5, 20], [9, 20], [8, 19], [0, 22], [10, 22], [6, 25], [1, 20]]. each do |task|
      assert(tg_adj[task] != nil)
    end

    assert(tg_adj[[4,19]].include?([4, 5, 22]))

    assert(tg_adj[[5,20]].include?([4, 5, 22]))
    assert(tg_adj[[5,20]].include?([5, 9, 22]))
    assert(tg_adj[[5,20]].include?([5, 8, 29]))
    assert(tg_adj[[5,20]].include?([5, 0, 29]))
    assert(tg_adj[[5,20]].include?([5, 10, 20]))

    assert(tg_adj[[9,20]].include?([5, 9, 22]))

    assert(tg_adj[[8,19]].include?([5, 8, 29]))

    assert(tg_adj[[0,22]].include?([5, 0, 29]))
    
    assert(tg_adj[[10,22]].include?([5, 10, 20]))

    assert(tg_adj[[6,25]].include?([8, 6, 25]))

    assert(tg_adj[[1,20]].include?([9, 1, 22]))

    # should not change tg
    assert(tg == [
          [[4, 19], [5, 20], [9, 20], [8, 19], [0, 22], [10, 22], [6, 25], [1, 20]], 
          [[4, 5, 22], [5, 9, 22], [5, 8, 29], [5, 0, 29], [5, 10, 20], [8, 6, 25], [9, 1, 22]]
         ])
    
  end


  def test_sort_by_subtree_size!
    tg = [
          [[4, 19], [5, 20], [9, 20], [8, 19], [0, 22], [10, 22], [6, 25], [1, 20]], 
          [[4, 5, 22], [5, 9, 22], [5, 8, 29], [5, 0, 29], [5, 10, 20], [8, 6, 25], [9, 1, 22]]
         ]

    sort_by_subtree_size!(tg)
    
    #crappy tests better than no tests... right?
    assert(tg[0][0] == [4,19])
    assert(tg[0][1] == [5,20])
    assert(tg[0][2] == [9,20] || tg[0][2] == [8,19])
    assert(tg[0][3] == [9,20] || tg[0][3] == [8,19])
    assert(tg[0][4] == [10,22] || tg[0][4] == [1,20] || tg[0][4] == [6,25] || tg[0][4] == [0,22])
    assert(tg[0][5] == [10,22] || tg[0][5] == [1,20] || tg[0][5] == [6,25] || tg[0][5] == [0,22])
    assert(tg[0][6] == [10,22] || tg[0][6] == [1,20] || tg[0][6] == [6,25] || tg[0][6] == [0,22])
    assert(tg[0][7] == [10,22] || tg[0][7] == [1,20] || tg[0][7] == [6,25] || tg[0][7] == [0,22])

  end

  def test_start_times
    tg = [
          [[4, 19], [5, 20], [9, 20], [8, 19], [0, 22], [10, 22], [6, 25], [1, 20]], 
          [[4, 5, 22], [5, 9, 22], [5, 8, 29], [5, 0, 29], [5, 10, 20], [8, 6, 25], [9, 1, 22]]
         ]

    starts = start_times(tg,{},4)
    
    assert_equal(0,starts[[4,19]])
    assert_equal(42,starts[[5,20]])
    assert_equal(85,starts[[9,20]])
    assert_equal(93,starts[[8,19]])
    assert_equal(93,starts[[0,22]])
    assert_equal(84,starts[[10,22]])
    assert_equal(140,starts[[6,25]])
    assert_equal(129,starts[[1,20]])
  end

end
