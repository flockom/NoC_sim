load '../scrape.rb'
load '../algorithms.rb'
load '../driver.rb'
load '../mapping_algorithms.rb'
load '../tgff_scrape.rb'

# TODO: make the gnuplot output automatically support more algorithms/different order

# this experiment will look at the performance of the algorithsm as the 
# occupancy(#tasks/#elemtns) changes. 
# Specificially it will use a fixed size task-graph and map it to 
# meshes of increasing size.

initial_mesh = 4        # size of the intial mesh n*(n+1)
num_meshes = 5     # each one is the next square from initial_mesh
num_graphs = 3     # number of task graphs to generate
num_faulty_sets=3 # number of faulty sets to test for every mesh and task graph and algorithm
weight = 0.5
algs = [:brute_force_optimal,:greedy,:hungarian,:random].collect {|m|method m}

# generate five task graphs
tgs = Array.new(num_graphs){|i|generate_tg(i,initial_mesh**2-1,10,30,100,20,10,2)}
# generate 5 faulty sets/graph

results = Array.new(num_meshes){Array.new(algs.size){0}} # 4 algorithms

xtics = ""
num_meshes.times do |i|
  puts "starting mesh #{i+1}/#{num_meshes}"
  #nx(n+1) mesh
  cols = (initial_mesh+i+1)  
  rows = (initial_mesh+i)
  redundant = right_col_redundant(cols,rows)

  #for gnuplot
  xtics += "\"#cores=#{(cols-1)*rows}\" #{i+1} -1#{(i==num_meshes-1)?"":","}"

  tgs.each do |tg|
    # map to the mesh
    mapped_graph = random_mapping(tg,cols,rows,redundant)
    generate_faulty_set(mapped_graph,initial_mesh,num_faulty_sets).each do |f|
      # run each algorithm
      algs.each_with_index do |alg,ii|
        puts "starting alg #{alg}"
        #average the results for every mesh size(i), for each algorithm(ii)
        res = alg.call(mapped_graph,f,redundant,cols,weight)        
        results[i][ii] += 
          similarity(mapped_graph,res,cols,weight)/(tgs.size*num_faulty_sets)
      end
    end    
  end
end


#write out the gnuplot data file
File.open("temp.dat", 'w') do |hist|
  results.each do |avgs| 
    hist.write("#{avgs[0]} #{avgs[1]} #{avgs[2]} #{avgs[3]}\n")
  end
end

#write out the gnuplot commands
gnuplot = <<END
set terminal png
set output "occupancy_comp.png"

set style data histogram
set style histogram cluster gap 1
set style fill solid 1.00 border -1

set format y ""
set format x ""

set key horizontal


set xtics norangelimit
set xtics (#{xtics})

set title  "Algorithm Comparison at #{num_meshes} Occupancy levels \\n of #{num_graphs} task graphs with #{initial_mesh**2} tasks each with #{num_faulty_sets} faulty sets"

set xlabel "Occupancy"
set ylabel "Similarity to Default"


plot 'temp.dat' using 1 t "optimal",'' using 2 t "greedy",'' using 3 t "hungarian",'' using 4 t "random"


END
File.open("temp.gnu", 'w') do |f|
  f.write gnuplot
end

#run gnuplot
`gnuplot temp.gnu`



