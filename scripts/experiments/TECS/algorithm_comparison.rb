# This experiment compares several algorithms average performance under a configurable number of mesh sizes

# Author: Frank Lockom

load '../../scrape.rb'
load '../../algorithmsTECS.rb'
load '../../mapping_algorithms.rb'
load '../../tgff_scrape.rb'
load '../../rrcs.rb'


start_time = Time.now

# 3x3, 4x4, 5x5, 6x6, 7x7
mesh_sizes = [[4,3],[5,4],[6,5],[7,6],[8,7]]
#
# generate num_graphs task graphs per mesh
num_graphs = 15

# generate num_faulty faulty sets per graph
num_faulty = 15

# algorithms to test
# [method(:random),method(:greedy),method(:brute_force_optimal)]
algs = [method(:random),method(:rrcs_1),method(:greedy_ESTIMEDIA),method(:greedy),method(:brute_force_optimal)]



# generate the task graphs, their mappings(to virtual cores) and their faulty sets
problems = Array.new(mesh_sizes.size) do |i|

  # so tgff does not generate too many tasks i.e. more than available cores
  size = mesh_sizes[i][1]**2-mesh_sizes[i][1] 

  tasks = Array.new(num_graphs) do    
     # generate the mapped task graphs
    begin #somtimes tgff gives us too many tasks, so do it a few times
        tg = random_mapping(
                         generate_tg(
                                     rand(1000),size,size,size,
                                     20,15,
                                     20,15),
                         mesh_sizes[i][1],mesh_sizes[i][1],# map to the virtual(square)
                         [])
      end while(tg == nil)
    [    
     tg,     
     # generate the faulty sets
     generate_faulty_set(tg,mesh_sizes[i][1],num_faulty)
     ]
  end
end

# Now we need to translate the the mapping and faulty cores from virtual cores
# on the nxn grid to the physical cores with our chosen distribution of redundant cores.


# we want one set for a physical topology with right column redundant (for RRCS)

#copy problems
problems_right_col_redundant = Array.new(problems.size) do |i|
  Array.new(problems[i].size) do |ii|
    [
     copy_tg(problems[i][ii][0]),
     Array.new(problems[i][ii][1].size) {|iii| Array.new(problems[i][ii][1][iii])}
    ]
  end
end


problems_right_col_redundant.each_with_index do |problem,i|

  problem.each do |ii|
    redundant = right_col_redundant(mesh_sizes[i][0],mesh_sizes[i][1])
    #convert the task graph
    tg_virtual_to_physical!(ii[0],mesh_sizes[i][1],mesh_sizes[i][1],redundant)
    #convert the faulty cores
    ii[1].each {|f| faulty_virtual_to_physical!(f,redundant)}
  end
end



# and another for a physical topology with a more even distribution (for the other algs)
# we will try with the center column as redundant cores

#first copy it
problems_center_col_redundant = Array.new(problems.size) do |i|
  Array.new(problems[i].size) do |ii|
    [
     copy_tg(problems[i][ii][0]),
     Array.new(problems[i][ii][1].size) {|iii| Array.new(problems[i][ii][1][iii])}
    ]
  end
end
problems_center_col_redundant.each_with_index do |problem,i|
  problem.each do |ii|
    redundant = center_col_redundant(mesh_sizes[i][0],mesh_sizes[i][1])
    #convert the task graph
    tg_virtual_to_physical!(ii[0],mesh_sizes[i][1],mesh_sizes[i][1],redundant)
    #convert the faulty cores
    ii[1].each {|f| faulty_virtual_to_physical!(f,redundant)}
  end
end

# for each algorithm get the solution for each problem
solns = Array.new(algs.size) do |alg|
  if algs[alg] == method(:rrcs_1)
     problems_here = problems_right_col_redundant
    gen_redundant = method(:right_col_redundant)
  else
     problems_here = problems_center_col_redundant
    gen_redundant = method(:center_col_redundant)
  end
  puts "Starting algorithm #{alg}"
  Array.new(mesh_sizes.size) do |mesh|
    results = Array.new
    puts "  Starting mesh #{mesh_sizes[mesh][1]}x#{mesh_sizes[mesh][1]}"
    num_graphs.times do |tg|
      num_faulty.times do |f|
        results <<
          euclidean_distance(
                             problems_here[mesh][tg][0],
                             algs[alg].call(
                                            problems_here[mesh][tg][0],
                                            problems_here[mesh][tg][1][f],
                                            gen_redundant.call(mesh_sizes[mesh][0],mesh_sizes[mesh][1]),
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

