# algorithmsTECS.rb
# Author: Frank Lockom
#
# algorithms to select the best replacemnt stratedgy for the TECS
# paper, using the euclidean distance of starting times metric
#
# Again, some code may be copied directly from algorithms.rb (from the old papers)
# just to keep things seperate

require_relative 'metricsTECS.rb'

# greedy algorithm, replaces cores  by subtree size of the task mapped to it
# minimizing the starting time of the task to be replaced at each step
def greedy(tg,faulty,replacements,n)
  result = Hash.new

  # sort tg by # successors
  sort_by_subtree_size!(tg)

  # sort faulty by # successors
  faulty.sort_by!{|a| tg[0].index(lookup_task(tg,a))}
  
  faulty.each do |fault|
    # pick the replacement which minimizes starting time of fault
    choice = replacements.min_by{|a| euclidean_distance(tg,result.merge({fault=>a}),n)}
    # add the mapping to the solution
    result[fault] = choice
    # remove the replacement from the set
    replacements.delete(fault)
  end
  return result
end


# random algorithm - randomly picks a mapping
def random(tg,faulty,replacements,n)
  get_mappings(faulty,replacements).sample
end


#finds the optimal solution using brute force
# tg           - the task graph with default mapping
# faulty       - array of faulty cores in tg
# replacements - array of possible replacement cores 
# n            - n column mesh
#weight         - weight given to average, weight given to variance is 1-weight
def brute_force_optimal(tg,faulty,replacements,n)
  if tg[1].size == 0 # special case if there are no edges(all replacements are equal)
    return get_mappings(faulty,replacements)[0] # return the first mapping
  end
  get_mappings(faulty,replacements).min_by do |a|
      euclidean_distance(tg,a,n) 
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
