# scrape_test.rb
# Author: Frank Lockom
# tests for scrape.rb functions

require_relative '../scrape.rb'

class ScrapeTest < Test::Unit::TestCase
  def test_read_TG
    #first test without comments
    read_TG('task-graphs/test_read_TG1')
  end
end
