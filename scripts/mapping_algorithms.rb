# mapping_algorithms.rb
# Author: Frank Lockom
#
# methods to map a task graph to nxm cores.
# where n=#cols and m=#rows
# returns a new task graph where the node id is the core its mapped to
# tasks will not be mapped to redundant cores 


# how to handle location of redundant cores?
#  -specifiy the redundant cores in an array redundant  
#  -the #tasks must be less than n*m-redundant
#  -nthe index in the array refers to the task # which goes from 0 to #tasks
#  -so swap all the redundant mappings to the end of the mapping array
#  -then do the mapping... none of the tasks will be mapped to redundant cores

def random_mapping(tg,n,m,redundant)
  #so we need a random sequence of unique numbers between 0 and nxm-1-redundant
  #... and thats our mapping!
  s = n*m-redundant.size
  mapping = Array.new(n*m) {|i| i}

  #swap the redundant cores to the end
  redundant.each_with_index do |r,i| 
    mapping[r],mapping[s+i] = [mapping[s+i],mapping[r]]
  end

  puts mapping
  puts "hokay?"
  
  #swap around the remining cores to get the mapping
  (s).times do 
    a,b = [rand(s),rand(s)]
    mapping[a],mapping[b] = [mapping[b],mapping[a]]
  end

  puts mapping

  #now build the new tg from the old one
  result = [Array.new(tg[0].size),Array.new(tg[1].size)]

  #swap the verticies
  tg[0].each_with_index do |v,i|
    result[0][i] = Array.new([mapping[i],v[1]])
  end
  
  #swap the edges
  tg[1].each_with_index do |e,i|
    result[1][i] = Array.new([mapping[e[0]],mapping[e[1]],e[2]])
  end
  
  result
  
end
