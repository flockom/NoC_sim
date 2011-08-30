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
end
