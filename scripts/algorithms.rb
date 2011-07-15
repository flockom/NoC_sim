# algorithms.rb
# Author: Frank Lockom
#
# algorithms to select the best replacemnt stratedgy

require_relative 'metrics.rb'



# going to cheat here, instead of implementing hungarian alg.
# I will do brute-force search of the matrix... result is the same ;)
# when n becomes too large I might have to implement it properly
def hungarian(tg,faulty,replacements,n,weight)
  cost = lambda {|mapping| 
    mapping.each_pair.inject(0.0) {|sum,kv|
      sum+similarity(tg,{kv[0]=>kv[1]},n,weight)
    }
  }
  get_mappings(faulty,replacements).min do |a,b|
    cost.call(a) <=> cost.call(b)
  end
end

# randomly picks a mapping
def random(tg,faulty,replacements,n,weight)

end

def greedy(tg,faulty,replacements,n,weight)
  solution = Hash.new
  tgp = copy_tg(tg)
  repl = Array.new(replacements)
  #sort faulty on total tfo from the default mapping
  faulty.sort!{|a,b| 
    total_tfo(tgp,{},b,n) <=> total_tfo(tgp,{},a,n) # sort by max
    #total_tfo(tgp,{},a,n) <=> total_tfo(tgp,{},b,n) # sort by min
  }
  #remove all nodes/edges in faulty from tg
  tgf = remove_nodes!(tgp,faulty)
  faulty.each do |f|
    #add each core back to tgp from tgf
    move_node!(tgp,tgf,f)
    #find its optimal replacement in order    
    lopt = brute_force_optimal(tgp,[f],repl,n,weight)
    solution.merge!(lopt)
    #remove the choice from the redundant set
    repl.delete(lopt[f])
    #change f to lopt[f] in tgp and tgf
    update_tg!(tgp,lopt)
    update_tg!(tgf,lopt)
  end
  solution
end


# modifies tg so that it reflects the mapping
# tg      -  a task graph
# mapping - a hash of old_tid=>new_tid
def update_tg!(tg,mapping)
  mapping.each_pair do |old,new|
    tg[0].each do |node|
      node[0] = new if node[0] == old
    end
    
    tg[1].each do |edge|
      edge[0] = new if edge[0] == old
      edge[1] = new if edge[1] == old
    end
  end
  return tg
end

# move all nodes/edges in tga to tg which involve the node i
# AND are present in tg
# modifies: tg,tga
def move_node!(tg,tga,i)
  #first just add node i in
  tga[0].each_index do |ii|
    if (i == tga[0][ii][0])
      tg[0].push(tga[0][ii])
      tga[0][ii] = nil
      break
    end
  end
  #then add the edges, only add edges for which both nodes exist in tg  
  tga[1].each_index do |ii|
    if tg[0].index{|item| item[0] == tga[1][ii][0]} && tg[0].index{|item| item[0] == tga[1][ii][1]}
      tg[1].push(tga[1][ii])
      tga[1][ii] = nil
    end
  end
  tga[0].compact!
  tga[1].compact!
end


# removes a node from tg and returns it along with all of its edges in a seperate task graph
# WARNING - modifies tg
# tg      - task graph to remove from
# tiles   - array of tileIDs of nodes/edges to remove
# returns - the removed nodes/edges
def remove_nodes!(tg,tiles)
  result = [Array.new,Array.new]

  tg[0].each_index {|n|      # remove nodes
    tiles.each do |i|
      if i == tg[0][n][0]
        result[0].push(tg[0][n])
        tg[0][n] = nil
        break
      end    
    end
  }
  tg[1].each_index {|e|      # remove edges
    tiles.each do |i|
      if(tg[1][e][0] == i || tg[1][e][1] == i)        
        result[1].push(tg[1][e])
        tg[1][e] = nil
        break                # don't add edge twice
      end
    end
  }
  tg[0].compact!
  tg[1].compact!
  return result
end

# copy constructor...err function... method
def copy_tg(tg)
  result = [Array.new(tg[0].size),Array.new(tg[1].size)]
  tg[0].each_index do |n|
    result[0][n] = Array.new(tg[0][n])
  end
  tg[1].each_index do |e|
    result[1][e] = Array.new(tg[1][e])
  end
  result
end

#finds the optimal solution using brute force
# tg           - the task graph with default mapping
# faulty       - array of faulty cores in tg
# replacements - array of possible replacement cores 
# n            - n column mesh
#weight         - weight given to average, weight given to variance is 1-weight
def brute_force_optimal(tg,faulty,replacements,n,weight)
  if tg[1].size == 0 # special case if there are no edges(all replacements are equal)
    return get_mappings(faulty,replacements)[0] # return the first mapping
  end
  get_mappings(faulty,replacements).min do |a,b|
      similarity(tg,a,n,weight) <=> similarity(tg,b,n,weight)
  end
end



# gives all possible mappings from a set of faulty cores f to
# possible replacement cores r
#
# f::  an array of faulty cores ex. [3,4]
# r::  the possible replacement cores ex. [5,11,17,23,29]
#
# returns an array of the mappings
#  ex: [{3=>5,4=>23},{3=>23,4=>5},...] (20 of them for the example)
def get_mappings(f,r)
  results = Array.new
  r.combination(f.length) do |comb|
    comb.permutation do |perm|      
      m = Hash.new
      f.each_index {|i| m[f[i]] = perm[i]}
      results.push(m)
    end
  end  
  return results
end
