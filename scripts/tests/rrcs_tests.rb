require 'test/unit'
require_relative '../rrcs.rb'


class RrcsTest < Test::Unit::TestCase

  # the task graph does not matter
  def test_rrcs_1
    # no faulty cores... don't do anything
    assert_equal(
                 {0=>0, 1=>1, 2=>2, 3=>3, 
                   4=>4, 5=>5, 6=>6, 7=>7, 
                   8=>8, 9=>9, 10=>10, 11=>11},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[],[3,7,11],4))

    # just one in first row
    assert_equal(
                 {0=>1, 1=>2, 2=>3, 3=>"faulty", 
                   4=>4, 5=>5, 6=>6, 7=>7, 
                   8=>8, 9=>9, 10=>10, 11=>11},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[0],[3,7,11],4))
    
    # just one in first row
    assert_equal(
                 {0=>0, 1=>2, 2=>3, 3=>"faulty", 
                   4=>4, 5=>5, 6=>6, 7=>7, 
                   8=>8, 9=>9, 10=>10, 11=>11},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[1],[3,7,11],4))
    
    # just one in first row
    assert_equal(
                 {0=>0, 1=>1, 2=>3, 3=>"faulty", 
                   4=>4, 5=>5, 6=>6, 7=>7, 
                   8=>8, 9=>9, 10=>10, 11=>11},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[2],[3,7,11],4))

    # entire first row is faulty
    assert_equal(
                 {0=>4, 1=>5, 2=>3, 3=>"faulty", 
                   4=>8, 5=>6, 6=>7, 7=>"faulty", 
                   8=>9, 9=>10, 10=>11, 11=>"faulty"},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[0,1,2],[3,7,11],4))

    # entire first column
    assert_equal(
                 {0=>1, 1=>2, 2=>3, 3=>"faulty", 
                   4=>5, 5=>6, 6=>7, 7=>"faulty", 
                   8=>9, 9=>10, 10=>11, 11=>"faulty"},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[0,4,8],[3,7,11],4))

    # one in both first and last row
    assert_equal(
                 {0=>1, 1=>2, 2=>3, 3=>"faulty", 
                   4=>4, 5=>5, 6=>6, 7=>7, 
                   8=>9, 9=>10, 10=>11, 11=>"faulty"},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[0,8],[3,7,11],4))

    # entire second row
    assert_equal(
                 {0=>1, 1=>2, 2=>3, 3=>"faulty", 
                   4=>0, 5=>9, 6=>7, 7=>"faulty", 
                   8=>8, 9=>10, 10=>11, 11=>"faulty"},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[4,5,6],[3,7,11],4))

    #entire third row
    assert_equal(
                 {0=>1, 1=>2, 2=>3, 3=>"faulty", 
                   4=>0, 5=>6, 6=>7, 7=>"faulty", 
                   8=>4, 9=>5, 10=>11, 11=>"faulty"},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[8,9,10],[3,7,11],4))


    assert_equal(
                 {0=>1, 1=>2, 2=>3, 3=>"faulty", 
                   4=>0, 5=>9, 6=>7, 7=>"faulty", 
                   8=>4, 9=>10, 10=>11, 11=>"faulty"},
                 rrcs_1([[[0,5],[6,2],[10,3],[2,2]],[]],[6,5,8],[3,7,11],4))

    

    
  end
end
