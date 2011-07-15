load '../scrape.rb'
load '../algorithms.rb'
load '../driver.rb'


# This experiment compares the different algorithms.
# It compares the similarity of optimal,greedy,hungarian and random algorithms to the default
# Runs some experiments... generates a csv file to 'outfile.csv', import to excel... nice
# run like this: 
# $ ruby experiments.rb outfile.csv

#need to override the array and hash to_s methods to be compatible with csv files(escape commas)
class Array
  alias to_s_old to_s
  def to_s
    "\""+to_s_old+"\""
  end
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

#App1(formerly known as app2)
tg = read_TG(tgfile)
a1f1 = ["1 Faulty",[[3],[4],[14],[24],[28]]]
a1f2 = ["2 Faulty",[[3,4],[3,24],[3,28],[13,20],[13,27]]]
a1f3 = ["3 Faulty",[[3,4,20],[3,13,20],[4,24,27],[13,20,27],[3,13,27]]]
a1f4 = ["4 Faulty",[[3,4,13,27],[3,13,20,27],[4,13,20,27],[3,4,24,28],[13,20,24,27]]]
a1f5 = ["5 Faulty",[[3,4,13,20,27],[3,4,20,24,27],[3,4,24,28,27],[13,20,24,27,28],[4,20,24,27,28]]]
app1 = [a1f1,a1f2,a1f3,a1f4,a1f5]


File.open(ARGV[0], 'w') do |out|
  # write some info
  out.write "info:\n"
  out.write "weights are 0.5 on average and variance for all experiments\n"
  out.write "the task graph gives the default mapping\n"
  out.write "\n\n\n"
  
  # column names
  out.write("Task Graph, Replacement Cores,Faulty Cores,"+
            "Optimal Re-Mapping (metric),\"Optimal Re-Mapping Similarity (metric, to default)\","+
            "Greedy Re-Mapping,Greedy Re-Mapping Similarity (to default),"+
            "Hungarian Re-Mapping,Hungarian Re-Mapping Similarity (to default)\n")
  
  
  out.write("Application 1\n")
  out.write("#{tg},#{replacements}\n")  
  app1.each do |fs|
    out.write(",#{fs[0]}\n")
    fs[1].each do |f|
      opt = brute_force_optimal(tg,f,replacements,cols,weight)
      opt_sim = similarity(tg,opt,cols,weight)
      greed = greedy(tg,f,replacements,cols,weight)    
      hung = hungarian(tg,f,replacements,cols,weight)

      greedy_sim = similarity(tg,greed,cols,weight)
      hung_sim = similarity(tg,hung,cols,weight)
      # TODO: add hungarian here
      out.write(",,#{f},#{opt},#{opt_sim},#{greed},#{greedy_sim},#{hung},#{hung_sim}\n")
    end
    out.write("\n")
  end

end

