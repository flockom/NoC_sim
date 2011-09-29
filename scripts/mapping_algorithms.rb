# mapping_algorithms.rb
# Author: Frank Lockom
#
# methods to map a task graph to nxm cores.
# where n=#cols and m=#rows
# returns a new task graph where the node id is the core its mapped to
 



# how to handle location of redundant cores?
def random_mapping(tg,n,m)
  #so we need a random sequence of unique numbers between 0 and nxm-1
  #... and thats our mapping!
  s = n*m
  mapping = Array.new(s) {|i| i}
  (s).times do 
    a,b = [rand(s),rand(s)]
    mapping[a],mapping[b] = [mapping[b],mapping[a]]
  end
  
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
