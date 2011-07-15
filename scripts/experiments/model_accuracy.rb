load '../scrape.rb'
load '../algorithms.rb'
load '../driver.rb'


#need to override the array and hash to_s methods to be compatible with csv files(escape commas)
class Array
  alias to_s_old to_s
  def to_s
    "\""+to_s_old+"\""
  end

  def variance ; self.squares.to_f/self.size - self.mean**2; end
  def squares ; self.inject(0){|a,x|x**2+a} ; end
  def mean ; self.sum.to_f/self.size ; end
  def sum ; self.inject(0){|a,x|x+a} ; end
end

class Hash
  alias to_s_old to_s
  def to_s
    "\""+to_s_old+"\""
  end
end

tgfile = './task-graphs/App2TGN'
replacements = [5,11,17,23,29]
weight = 0.5
cols = 6
tg = read_TG(tgfile)

File.open(ARGV[0], 'w') do |out|
# model accuracy experiment
  model_f_set = [3] # this is kind of random
  out.write(",Model Accuracy(Application1 faulty set: #{model_f_set})\n")
  out.write(",Mapping,similarity(metric),"+
            "similarity(simulation:communication time),difference %(metric-simulation)/simulation\n")
  #run nirgam get default communication times  
  run_replacement('../../',tgfile,{})
  default_comm_t = get_tt_average_comm_time('../../log/traffic/')

  diff = Array.new
  get_mappings(model_f_set,replacements).each do |mapping|
    metric_sim = similarity(tg,mapping,cols,weight)
    run_replacement('../../',tgfile,mapping) # run nirgam
                   # get results
    simulation_sim = similarity(tg,mapping,
                                cols,weight,get_tt_average_comm_time('../../log/traffic/'),
                                default_comm_t)
    diff.push((metric_sim - simulation_sim)/simulation_sim)
    out.write(",#{mapping},#{metric_sim},#{simulation_sim},#{diff[diff.size-1]}\n")
  end

  out.write(",,,,Standard Deviation:\n")
  out.write(",,,,#{Math.sqrt(diff.variance)}\n")
end
