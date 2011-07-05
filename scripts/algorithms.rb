# algorithms.rb
# Author: Frank Lockom
#
# algorithms to select the best replacemnt stratedgy

require_relative 'metrics.rb'


def greedy(tg,faulty,replacements,n,weight)
  #sort faulty on total tfo from the default mapping
  faulty.sort!{|a,b| 
    total_tfo(tg,{},a,n) <=> total_tfo(tg,{},b,n)
  }
  #remove all nodes/edges in faulty from tg
  tgp = remove_nodes(tg,faulty)
  faulty.each do |f|
    #add each core back to tg and find its optimal replacement in order
    
    #add the optimal replacement into tg
  end
end


# removes a node from tg and returns it along with all of its edges in a seperate task graph
# WARNING: modifies tg - should change this, but need to copy array manually, copy constructor does not recurse
# tg      - task graph to remove from
# tiles   - array of tileIDs of nodes/edges to remove
# returns - the nodes/edges removed in a seperate tg
def remove_nodes(tg,tiles)
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

#finds the optimal solution using brute force
# tg           - the task graph with default mapping
# faulty       - array of faulty cores in tg
# replacements - array of possible replacement cores 
# n            - n column mesh
#weight         - weight given to average, weight given to variance is 1-weight
def brute_force_optimal(tg,faulty,replacements,n,weight)
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
