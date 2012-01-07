# These are metrics used in the TECS journel submission
# I am going to keep these seperate from old metrics (metrics.rb)
# for organization and self containment, even if I duplicate some code.



# gets the euclidean distance between the default and replacement stratedgy
# tg      - the default mapping
# mapping - the replacement stratedgy
# n       - n column mesh
# weight  - weight given to average, weight given to variance is 1-weight
# sim     - a hash of {src=>dest}=>communication_time - if its nil then tfo is used
# default - a hash of {src=>dest}=>communication_time for the default mapping i.e. tg
def euclidean_distance(tg,mapping,n,sim = nil, default = nil)
  default = start_times(tg,{},n,nil,default)
  reconfig = start_times(tg,mapping,n,sim,nil)
  Math.sqrt(default.reduce(0){|sum,kv|sum + (default[kv[0]]-reconfig[kv[0]])**2.0})
end


# calculates the start times of every task in tg(a mapped task graph)
# given a replacement stratedgy, mapping.
# see commmunication_time method for the parameters
# start time of a task is the max of all its predecessors start_time+execution_time+communication_time
# so it is efficient to just calculate them all together, in a BFS.
#
# returns a hash of start times as [id,exec]=>start_time
# where [id,exec] are from tg[0] (see scrape.rb for task graph format)
def start_times(tg,mapping,n,sim=nil,default=nil)
  # order tasks by subtree size, and get adjacency list
  tg_adj = sort_by_subtree_size!(tg)

  # calculate start time by filling in table in order of subtree size
  result = Hash.new
  tg[0].each do |task|
    #collect all the tasks parents (tg_matrix[task][i] = [parent,task[0],,])
    parents = Array.new
    tg_adj[task].each do |edge|
      if edge[1] == task[0] #found a parent task
        parents << [lookup_task(tg,edge[0]),edge]
      end
    end

    # find the critical parent (last to finish communicating)
    critical = 
      parents.max_by {|depend| 
      result[depend[0]]+
      depend[0][1]+
      communication_time(tg,mapping,depend[1][0],depend[1][1],n)
    } #start+exec+comm
    
    # thats the start time of this task, unless it has no parent
    if critical == nil
      result[task] = 0
    else
      result[task] = 
        result[critical[0]]+
        critical[0][1]+
        communication_time(tg,mapping,critical[1][0],critical[1][1],n)
    end
  end
  return result
end




# gets the task in tg[0] with id
def lookup_task(tg,id)
  result = nil
  tg[0].each do |task|
    result = task if task[0] == id
  end
  result
end



# modifes tg[1] so that tasks are ordered by the size of the subtree they
# are rooted in (total # successors)
# returns the adjacency list for convenience
def sort_by_subtree_size!(tg)
  # create an adjacency list with tg
  tg_adj = build_adjacency_list(tg)

  # create a hash of [id,exec]=>subtree_size, fill in using DFS ordering
  subtree_sizes = Hash.new

  #DFS(there are no cycles)
  dfs_stack = Array.new
  # find the root task(s), push to stack
  tg_adj.each_pair do |task,edges|
    root  = true
    edges.each do |edge|
      root = false if edge[1] == task[0]
    end
    dfs_stack.push(task) if root
  end

  while(task = dfs_stack.last)
    finished = true # all children are finished
    
    # push unfinished children onto stack
    children = Array.new    
    tg_adj[task].each do |edge|      
      if edge[0] == task[0]
        if  subtree_sizes[child=lookup_task(tg,edge[1])] == nil # this child is not finished
          finished = false
          dfs_stack.push child
        end
        children << child
      end
      
    end
    
    if finished
      dfs_stack.pop
      subtree_sizes[task] = children.reduce(0){|total,child| total+1+subtree_sizes[child]}
    end
  end
  
  # sort tg on subtree size
  tg[0].sort! {|a,b| subtree_sizes[b] <=> subtree_sizes[a] }
  return tg_adj
end


# builds and adjacency list of tg as a hash of 
# [id,exex]=>[edge1,edge2,edge3]
# both incoming and outgoing edges are added
def build_adjacency_list(tg)
  result = Hash.new
  tg[0].each do |task|
    result[task] = Array.new
    tg[1].each do |edge|
      result[task] << edge if edge[0] == task[0] or  edge[1] == task[0]
    end
  end
  return result
end

# volume+hop_count is communication time
# gets the traffic_flow_occupancy as defined in KE's paper
# tg      - the task graph. see read_TG(infile) for format
# mapping - the replacement stratedgy
# i,j     - get the time from virtual cores i->j
# n       - n column mesh
# sim     - a hash of {src=>dest}=>communication_time - if its nil then tfo is used, used for the simulated comm_time
# default - a hash of {src=>dest}=>communication_time for the default mapping i.e. tg, used for the simulated comm_time
def communication_time(tg,mapping,i,j,n,sim = nil,default = nil)  
  # get the physical core location
  pi = (mapping[i] == nil)? i : mapping[i]
  pj = (mapping[j] == nil)? j : mapping[j]
  
  if sim != nil    
    return sim[{pi=>pj}]     if mapping != {}
    return default[{pi=>pj}] 
  end

  volume = 0
  # get the volume
  tg[1].each do |edge|
    if(edge[0] == i && edge[1] == j )
      volume = edge[2] 
    end
  end
  volume + hop_count_XY(pi,pj,n)
end

# gets the hop count from physical core i to j
# using XY routing with a mesh of size n columns
def hop_count_XY(i,j,n)
  (i%n - j%n).abs + (i/n - j/n).abs
end
