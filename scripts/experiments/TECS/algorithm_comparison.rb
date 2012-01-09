load '../../scrape.rb'
load '../../algorithmsTECS.rb'
load '../../mapping_algorithms.rb'
load '../../tgff_scrape.rb'


start_time = Time.now

# 3x3, 4x4, 5x5, 6x6, 7x7
mesh_sizes = [[4,3],[5,4],[6,5],[7,6]]

# generate num_graphs task graphs per mesh
num_graphs = 1

# generate num_faulty faulty sets per graph
num_faulty = 1

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
  {algs[alg].name =>
  Array.new(mesh_sizes.size) do |mesh| 
    solns[alg][mesh].reduce(:+)/solns[alg][mesh].size.to_f
  end
  }
end

puts averages.to_s

puts "Total run-time: #{Time.now - start_time} seconds"
