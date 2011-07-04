# algorithms.rb
# Author: Frank Lockom
#
# algorithms to select the best replacemnt stratedgy

require_relative 'metrics.rb'


def greedy(tg,faulty,replacements,n,weight)
  
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
