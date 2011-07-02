# scrape_test.rb
# Author: Frank Lockom
# tests for scrape.rb functions

require 'test/unit'
require_relative '../scrape.rb'

class ScrapeTest < Test::Unit::TestCase
  def test_read_TG
    #first test without comments
    tg = read_TG('task-graphs/test_read_TG1')
    assert_equal(4,tg[0].size)
    assert_equal(3,tg[1].size)
    assert_equal([0,1,5],tg[1][0])
    assert_equal([0,8,2],tg[1][1])
    assert_equal([0,10,3],tg[1][2])

    #now test with comments
    tg = read_TG('task-graphs/test_tfo1')
    assert_equal(4,tg[0].size)
    assert_equal(3,tg[1].size)
    assert_equal([0,1,5],tg[1][0])
    assert_equal([0,8,2],tg[1][1])
    assert_equal([0,10,3],tg[1][2])
  end
end
