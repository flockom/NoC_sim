load '../../scrape.rb'
load '../../algorithmsTECS.rb'
load '../../rrcs.rb'
load '../../metricsTECS.rb'
load '../../mapping_algorithms.rb'


#Task graph 2 from the E3S automotive suite 
cols = 5
rows = 4
tgfile = '../task-graphs/App2TGN_unmapped'
tg = random_mapping(read_TG(tgfile),cols,rows,right_col_redundant(cols,rows))




# get the redundant cores
replacements_right_col = right_col_redundant(cols,rows) 
replacements_non_mapped = unmapped_redundant(tg,cols,rows)


# pick some faulty cores
faulty = generate_faulty_set(tg,rows,1)[0]

# get default starting times
default_start_times = start_times(tg,{},cols)



# get rrcs, greedy_esti,greedy and optimal solutions.
# get starting time for each task for each solution
algs = [method(:rrcs_1),method(:greedy_ESTIMEDIA),method(:greedy),method(:brute_force_optimal)]
solutions_dist = Array.new(algs.size)
solns = Array.new(algs.size) do |alg|
  replacements = ((algs[alg]==method(:rrcs_1))?replacements_right_col:replacements_non_mapped)
  solutions_dist[alg] = algs[alg].call(tg,faulty,replacements,cols)
  st = start_times(tg,solutions_dist[alg],cols)
  st_delta = Hash.new
  st.each_key {|task| st_delta[task] = (st[task]-default_start_times[task]).abs}# delta from default
  st_delta
end

#record the solutions distance
solutions_dist.size.times do |sol|
  solutions_dist[sol] = euclidean_distance(tg,solutions_dist[sol],cols)
end


# get all solutions, sum starting time for each task across the solution space
average_soln = Hash.new(0) # default value is 0
mappings = get_mappings(faulty,replacements_non_mapped)
mappings.each do |mapping|
  start_times(tg,mapping,cols).each_pair do |task,time|
    average_soln[task] = average_soln[task]+time
  end
end

# take the average and then the difference from default
average_soln.each_key do |task| 
  average_soln[task] = (average_soln[task]/mappings.size.to_f-default_start_times[task]).abs
end

# put it at the front
solns = solns.insert(0,average_soln)


# write the data out for gnuplot
puts solns.to_s
File.open("temp.dat","w") do |hist|
  
  solns[0].each_key do |task|
    (solns.size).times do |alg|
      hist.write("#{solns[alg][task]} ")
    end
    hist.write("\n")
  end
end



# graph it
xtics = ""
i = 0
solns[0].each_key do |key|
  xtics+= "\"#{i}\" #{i+1} -1#{(i == solns[0].size-1 )?"":", "}"
  i+=1
end

plot = "'temp.dat' using 0 t \"average\""
(1..(algs.size)).each do |alg|
  plot += ", '' using #{alg} t \"#{algs[alg-1].name}-#{solutions_dist[alg-1]}\""
end

gnuplot = <<END
set terminal png
set output "start_time_comparison.png"

set style data histogram
set style histogram cluster gap 1
set style fill solid 1.00 border -1

#set format y ""
set format x ""

set key horizontal


set xtics norangelimit
set xtics (#{xtics})

set title  "task starting time comparison"

set xlabel "task"
set ylabel "starting time delta"


plot #{plot}


END
File.open("temp.gnu", 'w') do |f|
  f.write gnuplot
end

#run gnuplot
`gnuplot temp.gnu`
