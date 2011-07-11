# algorithms_test.rb
# Author: Frank Lockom

require 'test/unit'
require_relative '../scrape.rb'
require_relative '../algorithms.rb'

class AlgorithmsTest < Test::Unit::TestCase

  def test_copy_tg
    tg1 = read_TG('./task-graphs/test_tfo1')
    tgg = copy_tg(tg1)
    assert_equal(tg1,tgg)  

    #change one
    tg1[0][0] = nil
    assert_not_equal(tg1,tgg)  
  end

  def test_remove_nodes!
    # remove 1
    tg1 = read_TG('./task-graphs/test_tfo1')
    tgp = remove_nodes!(tg1,[8])
    assert_equal([[[0,1],[1,1],[10,1]],[[0,1,5],[0,10,3]]],
                 tg1)
    assert_equal([[[8,1]],[[0,8,2]]],tgp)

    #remove 2
    tg1 = read_TG('./task-graphs/test_tfo1')
    tgp = remove_nodes!(tg1,[8,10])
    assert_equal([[[0,1],[1,1]],[[0,1,5]]],
                 tg1)
    assert_equal([[[8,1],[10,1]],[[0,8,2],[0,10,3]]],tgp)

    #remove all
    tg1 = read_TG('./task-graphs/test_tfo1')
    tgp = remove_nodes!(tg1,[0])
    assert_equal([[[1,1],[8,1],[10,1]],[]],
                 tg1)
    assert_equal([[[0,1]],
                  [[0,1,5],[0,8,2],[0,10,3]]],tgp)    
  end
                       

  def test_move_node!
    tg1 = read_TG('./task-graphs/test_tfo1')
    tg1c = copy_tg(tg1)
    
    #bogus args
    move_node!(tg1,[[],[]],100)
    assert_equal(tg1,tg1c)

    #simple, move everything
    temp = [[[5,1]],[[5,0,2]]]
    move_node!(tg1,temp,5)
    assert_equal([[],[]],temp)
    tg1c[0].push([5,1])
    tg1c[1].push([5,0,2])    
    assert_equal(tg1c,tg1)

    #selective move
    tg1 = read_TG('./task-graphs/test_tfo1')
    tg1c = copy_tg(tg1)
    temp = [[[5,1],[7,1]],[[5,0,2],[8,5,2],[5,7,2]]]
    move_node!(tg1,temp,5)
    assert_equal([[[7,1]],[[5,7,2]]],temp)
    tg1c[0].push([5,1])
    tg1c[1].push([5,0,2],[8,5,2])
    assert_equal(tg1c,tg1)
  end

  def test_update_tg!
    #just do 1
    tg1 = [[[1,1],[5,2]],[[1,5,2]]]
    update_tg!(tg1,{1=>0})
    assert_equal([[[0,1],[5,2]],[[0,5,2]]],tg1)

    #now do n!
    tg1 = [[[1,1],[5,2]],[[1,5,2]]]
    update_tg!(tg1,{1=>0,5=>6})
    assert_equal([[[0,1],[6,2]],[[0,6,2]]],tg1)
  end

  def test_brute_force_optimal
    tg1 = read_TG('./task-graphs/test_tfo1')
    brute_force_optimal(tg1,[0],[3,7,11],4,0.5)
    
    #see if it even runs for multiple
    brute_force_optimal(tg1,[0,8],[3,7,11],4,0.5)
  end

  def test_greedy
    #test if it is the same as brute_force_optimal for 1 core
    tg1 = read_TG('./task-graphs/test_tfo1')
    assert_equal(brute_force_optimal(tg1,[0],[3,7,11],4,0.5),greedy(tg1,[0],[3,7,11],4,0.5))
    
    #see if it even runs for multiple
    greedy(tg1,[0,8],[3,7,11],4,0.5)        
  end
  
end
