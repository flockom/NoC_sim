# This experiment will look at the greedy algorithms absolute
# performance, it will order the greedy solution among all solutions
# and give the min, average, and standard deviation of the greedy
# algorithms rank amongst all solutions 

# Author: Frank Lockom

load '../../scrape.rb'
load '../../algorithmsTECS.rb'
load '../../mapping_algorithms.rb'
load '../../tgff_scrape.rb'

start_time = Time.now

# 3x3, 4x4, 5x5, 6x6, 7x7
mesh_sizes = [[5,4]]
#,[5,4],[6,5],[7,6]

# generate num_graphs task graphs per mesh
num_graphs = 20

# generate num_faulty faulty sets per graph
num_faulty = 20


# generate the task graphs, their mappings and their faulty sets
problems = Array.new(mesh_sizes.size) do |i|
  puts "Starting #{mesh_sizes[i][1]}x#{mesh_sizes[i][1]} mesh"
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


# TODO: remove duplicate solutions so the rank is not distorted by ties, not sure if we want that or not
#       note that index method gets the FIRST index which matches, so it would not negetivly effect the minimum.

# for each mesh size, look at each problem, find the rank of the greedy algorithm
# and keep a running tally of the min, average, and std deviation of the ranks
results = Array.new(mesh_sizes.size) do |mesh|
  greedy_ranks = Array.new
  stats = [1, 0.0, 0.0] # min(1=100% is last place),average,std deviation 
  num_graphs.times do |tg|
    num_faulty.times do |f|
      # get the greedy solution
      greedy_soln = greedy(problems[mesh][tg][0],
                           problems[mesh][tg][1][f],
                           right_col_redundant(mesh_sizes[mesh][0],mesh_sizes[mesh][1]),
                           mesh_sizes[mesh][0])
      # get all the solutions, sort by distance
      all_solns = get_mappings(problems[mesh][tg][1][f],right_col_redundant(mesh_sizes[mesh][0],mesh_sizes[mesh][1]))
      all_solns.sort_by!{|a| euclidean_distance(problems[mesh][tg][0],a,mesh_sizes[mesh][0])}
      #get the rank of the greedy alg     
      greedy_rank = (all_solns.size - all_solns.index(greedy_soln))/all_solns.size.to_f   
      stats[0] = [stats[0],greedy_rank].min
      stats[1] += greedy_rank
      greedy_ranks << greedy_rank
    end
  end
  #average
  stats[1] /= num_graphs*num_faulty 
  
  #calculate variance
  stats[2] = greedy_ranks.reduce{|sum,sol| sum+(sol-stats[1])**2}
  stats[2] = Math.sqrt(stats[2]/(num_graphs*num_faulty)) # standard deviation
  stats
end


puts results.to_s
