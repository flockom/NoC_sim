# algorithms_test.rb
# Author: Frank Lockom

require 'test/unit'
require_relative '../scrape.rb'
require_relative '../algorithms.rb'

class AlgorithmsTest < Test::Unit::TestCase
  def test_remove_nodes
    # remove 1
    tg1 = read_TG('./task-graphs/test_tfo1')
    tgp = remove_nodes(tg1,[8])
    assert_equal([[[0,1],[1,1],[10,1]],[[0,1,5],[0,10,3]]],
                 tg1)
    assert_equal([[[8,1]],[[0,8,2]]],tgp)

    #remove 2
    tg1 = read_TG('./task-graphs/test_tfo1')
    tgp = remove_nodes(tg1,[8,10])
    assert_equal([[[0,1],[1,1]],[[0,1,5]]],
                 tg1)
    assert_equal([[[8,1],[10,1]],[[0,8,2],[0,10,3]]],tgp)

    #remove all
    tg1 = read_TG('./task-graphs/test_tfo1')
    tgp = remove_nodes(tg1,[0])
    assert_equal([[[1,1],[8,1],[10,1]],[]],
                 tg1)
    assert_equal([[[0,1]],
                  [[0,1,5],[0,8,2],[0,10,3]]],tgp)    
  end
                       
end
