load '../scrape.rb'
load '../algorithms.rb'
load '../driver.rb'
load '../mapping_algorithms.rb'
load '../tgff_scrape.rb'

# for a fixed task graph and mesh size and a given algorithm
# show how the algorithm performs as the number of faulty cores increases
# x-axis: # faulty cores
# y-axis: similarity

num_graphs = 3 # number of graphs to test
num_faulty = 3 # number of faulty sets to test per graph per faulty number
graph_size = 7 # #tasks is about graph_size**2
mesh_size  = 8 # map to a mesh_size**2 mesh

alg = nil

case ARGV[0]
when "optimal"
  alg = :brute_force_optimal
when "greedy"
  alg = :greedy
when "hungarian"
  alg = :hungarian
when "random"
  alg = :random
end

if !alg
  exit(1)
end

alg = method alg


weight = 0.5
redundant = right_col_redundant(mesh_size+1,mesh_size)
#generate the graphs and map them
tgs = Array.new(num_graphs){
  random_mapping(generate_tg(rand(1000),graph_size**2-1,10,30,100,20,10,2),
                 mesh_size+1,mesh_size,
                 redundant)
  
}

results = Array.new(num_graphs){Array.new(mesh_size){Array.new(num_faulty)}}

tgs.each_with_index do |tg,i|
  puts "starting task graph #{i+1}/#{tgs.size}"
  mesh_size.times do |ii|
    puts "starting faulty cores #{ii+1}/#{mesh_size}"
    generate_faulty_set(tg,ii+1,num_faulty).each_with_index do |f,iii|
      res = alg.call(tg,f,redundant,mesh_size+1,weight)
      results[i][ii][iii] = similarity(tg,res,mesh_size+1,weight)
    end
  end
end



#write out the gnuplot data file
results.size.times do |i|
  File.open("scale_temp#{i}.dat", 'w') do |f|
    results[i].each_with_index do |mesh_size,ii| 
      f.write "#{ii+1} "#number of faulty cores
      mesh_size.each do |faulty|
        f.write "#{faulty} "
      end
      f.write "\n"
    end
  end
end


gnuplot = <<END
set terminal png
set output "scalability_comp.png"

set style data linespoints

#set format y ""
#set format x ""

#set title  ""

set xlabel "Number of Faulty cores"
set ylabel "Similarity to Default"


plot 'scale_temp0.dat' using 1:2 t "", '' using 1:3 t "", '' using 1:4 t "",\
     'scale_temp1.dat' using 1:2 t "", '' using 1:3 t "", '' using 1:4 t "",\
     'scale_temp2.dat' using 1:2 t "", '' using 1:3 t "", '' using 1:4 t ""


END


File.open("s_temp.gnu", 'w') do |f|
  f.write gnuplot
end

`gnuplot s_temp.gnu`
