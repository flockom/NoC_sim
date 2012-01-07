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
  return nil if tg[0].size > s  # not enough cores for tasks , error
  mapping = Array.new(n*m) {|i| i}

  #swap the redundant cores to the end
  redundant.each_with_index do |r,i| 
    mapping[r],mapping[s+i] = [mapping[s+i],mapping[r]]
  end

  #swap around the remining cores to get the mapping
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


# returns an array of redundant core indexes for  a
# nxm matrix with the right column acting as redundant cores
def right_col_redundant(cols,rows)
  result = Array.new(rows){|i| cols-1 + i*cols}
end



# generates x random faulty set of size n from
# the task graph tg
def generate_faulty_set(tg,n,x)
  #get the faulty edges  
  a  = Array.new(x){random_combination(tg[0],n)}

  #pull out the ids
  result = Array.new(a.size)
  a.each_with_index do |v,i|
    result[i] = Array.new(n){|ii| v[ii][0]}    
  end
  result
end

# look for a better implementation later
def random_combination(a,n)
  comb = Array.new(a.size){|i|i}
  #make |a| randomw swaps and pick the first n elements
  comb.size.times do 
    x,y = [rand(comb.size),rand(comb.size)]
    comb[x],comb[y] = [comb[y],comb[x]]
  end  
  return Array.new(n){|i|a[comb[i]]}
end

# TODO: Write this 
#
# Takes a mapped task graph and adds an injection rate to each edge
# (in addition to the volume) such that for any link in the NoC the
# total bandwidth usage does not excede (0<max_link_util<=1) under XY
# routing i.e the mapping satisfies guarenteed service.
#
# maped_tg:
# a mapped task graph as returned by random_mapping(tg,n,m,redundant)
#
# rows: # rows of the NoC mapped_tg is mapped to
# cols: see rows
#
# max_link_util:
# 0<max_link_util<=1 the max utilization on any link. The utilization on a link
# is the sum of the inverse of all injection rates of the edges 
# which cross the link under XY routing.
# 
#
def allocate_bandwidth_gs(maped_tg,max_link_util,rows,cols)

  links = all_links_mesh(rows,cols)
  
  #initialize the injection rate of each edge to the 'minimum'
  min_injection = 0.5*max_link_util/edgesXY(mapped_tg,links.max_by{|x|edgesXY(mapped_tg,x)})
  
  #copy mapped_tg, add injection rate to edge
  result = Array.new(2)
  result[0] = Array.new(maped_tg[0].size){|i| Array.new(maped_tg[0][i])}#copy tasks
  result[1] = Array.new(maped_tg[1].size){|i| Array.new(mapped_tg[1][i])<< min_injection}#copy edges

  #randomly order the edges to allocate bandwidth
  result[1].shuffle!.each do |edge|
    edge[3] = random(min_injection)+max_injection()#TODO: finish this
  end
  return result
end

#  - set all edges injection rate to min_injection
#  - randomly order edges
#  - choose injection rate between [max-injection(max_link_util,edge,min_injection),min_injection)
#  - min_injection = (0.5)*util/maxEdgesOverALink

# max_injection(util,edge) = 1/max_(foreach link used by edge under XY)(util-currentutilization-utilization(edge))
# 
# all_links_mesh(rows,cols)
# linksXY(maped_tgedge)
# edgesXY(maped_tg,link)

# gets the max injection rate which can be assigned to an edge and keep all links
# within a specified util
def max_injection(mapped_tg,rows,cols,util,edge)
  #get all links used by edge and their current allocated bandwidth
end

# returns an array of integers representing links for a mesh topology
# with r rows and c columns.
def all_links_mesh(r,c)

end

# counts the number of edges which cross a link under XY routing for a
# mapped task graph mapped_tg which is mapped to a mesh with rows rows
# and cols columns
def edgesXY(mapped_tg,rows,cols,link)
  
end
