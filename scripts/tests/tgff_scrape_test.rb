# scrape_test.rb
# Author: Frank Lockom
# tests for tgff_scrape.rb functions

require 'test/unit'
require_relative '../tgff_scrape.rb'



class TGFFScrapeTest < Test::Unit::TestCase
  def test_read_tgff
    should = [[[0,87],[1,95],[2,96],[3,96],[4,87]],[[0,1,3],[1,2,6],[0,3,9],[1,4,9],[3,4,8],[2,4,6],[0,4,4]]]
    actual = read_tgff('task-graphs/t1.tgff')
    assert_equal(should,actual)
  end

  def test_generate_tg
    #same random seed should give same graph...for 1 to 10?
    for i in 1..10 do
      assert_equal(generate_tg(i,10,5,6,100,20,10,5),generate_tg(i,10,5,6,100,20,10,5))
    end
  end
end
