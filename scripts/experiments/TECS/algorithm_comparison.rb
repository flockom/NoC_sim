# This experiment compares several algorithms average performance under a configurable number of mesh sizes

# Author: Frank Lockom

load '../../scrape.rb'
load '../../algorithmsTECS.rb'
load '../../mapping_algorithms.rb'
load '../../tgff_scrape.rb'


start_time = Time.now

# 3x3, 4x4, 5x5, 6x6, 7x7
mesh_sizes = [[4,3],[5,4],[6,5],[7,6]]

# generate num_graphs task graphs per mesh
num_graphs = 5

# generate num_faulty faulty sets per graph
num_faulty = 5

# algorithms to test
# [method(:random),method(:greedy),method(:brute_force_optimal)]
algs = [method(:random),method(:greedy),method(:brute_force_optimal)]



# generate the task graphs, their mappings and their faulty sets
problems = Array.new(mesh_sizes.size) do |i|
  size = mesh_sizes[i][1]**2-mesh_sizes[i][1]
  tasks = Array.new(num_graphs) do    
     # generate the mapped task graphs
    begin #somtimes tgff gives us too many tasks??? so do it a few times
        tg = random_mapping(
                         generate_tg(
                                     rand(1000),size,size,size,
                                     20,15,
                                     20,15),
                         mesh_sizes[i][0],mesh_sizes[i][1],
                         right_col_redundant(mesh_sizes[i][0],mesh_sizes[i][1]))
      end while(tg == nil)
    [    
     tg,     
     # generate the faulty sets
     generate_faulty_set(tg,mesh_sizes[i][1],num_faulty)
     ]
  end
end


# for each algorithm get the solution for each problem
solns = Array.new(algs.size) do |alg|
  puts "Starting algorithm #{alg}"
  Array.new(mesh_sizes.size) do |mesh|
    results = Array.new
    puts "  Starting mesh #{mesh_sizes[mesh][1]}x#{mesh_sizes[mesh][1]}"
    num_graphs.times do |tg|
      num_faulty.times do |f|
        results <<
          euclidean_distance(
                             problems[mesh][tg][0],
                             algs[alg].call(
                                            problems[mesh][tg][0],
                                            problems[mesh][tg][1][f],
                                            right_col_redundant(mesh_sizes[mesh][0],mesh_sizes[mesh][1]),
                                            mesh_sizes[mesh][0]
                                            ),
                             mesh_sizes[mesh][0]
                             )
      end
    end    
    results
  end
end


# for each mesh size, average the solutions for each algorithm
averages = Array.new(algs.size) do |alg|

  Array.new(mesh_sizes.size) do |mesh| 
    solns[alg][mesh].reduce(:+)/solns[alg][mesh].size.to_f
  end

end


puts averages.to_s

puts "Total run-time: #{Time.now - start_time} seconds"


#write data out for gnuplot
File.open("temp.dat","w") do |hist|
  
  mesh_sizes.size.times do |mesh|
    algs.size.times do |alg|
      hist.write("#{averages[alg][mesh]} ")
    end
    hist.write("\n")
  end
end



#write out the gnuplot commands

#get the xtics i.e 3x3, 4x4, 5x5
xtics = ""
mesh_sizes.size.times do |i|
  xtics += "\"#{mesh_sizes[i][1]}x#{mesh_sizes[i][1]}\" #{i+1} -1#{(i == mesh_sizes.size-1 )?"":", "}"
end

# plot command looks something like this:
# plot 'temp.dat' using 1 t "optimal",'' using 2 t "greedy",'' using 3 t "hungarian",'' using 4 t "random"
plot = "'temp.dat' using 1 t \"#{algs[0].name}\""
(2..(algs.size)).each do |alg|
  plot += ", '' using #{alg} t \"#{algs[alg-1].name}\""
end

gnuplot = <<END
set terminal png
set output "algorithm_comp.png"

set style data histogram
set style histogram cluster gap 1
set style fill solid 1.00 border -1

set format y ""
set format x ""

set key horizontal


set xtics norangelimit
set xtics (#{xtics})

set title  "Algorithm Comparison of #{mesh_sizes.size} virtual topology sizes \\n each with #{num_graphs} task graphs and #{num_faulty} faulty sets per graph"

set xlabel "virtual topology size (rows x columns)"
set ylabel "Average Starting time distance from reference topology"


plot #{plot}


END
File.open("temp.gnu", 'w') do |f|
  f.write gnuplot
end

#run gnuplot
`gnuplot temp.gnu`

