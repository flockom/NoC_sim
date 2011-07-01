# ttlatency.rb
# Author: Frank Lockom
# some routes for automating the nirgam task graph node (TGN) application


# TODO: - run_replacement cannot do a replacement to a tile 
#         which is in the default mapping
#       - oal does not check the directory from nirgam.config that
#         sim_results will be in
# 

# get best results from a mapping (like returned from run_all_replacements_given_faulty)
# default:: the default overall average latency(no faulty cores)
# m::       a hash of replacement stratedgy=>[overall average latency,tt_latency]
def get_best_oal(default, m)
  min = 10000 # yes this is dirty
  best = nil
  m.each_pair do |strat,oal|
    tmin = (default-oal[0]).abs
    if tmin < min
      best = strat
      min = tmin
    end
  end
  return [best,m[best]]
end

def get_best_ttl(default,m)
  min = 10000 # yes this is dirty
  best = nil
  m.each_pair do |strat,ttl|
    avgttl = average_tt_latency(ttl[1])
    tmin = (default-avgttl).abs
    if tmin < min
      best = strat
      min = tmin
    end
  end
  return [best,m[best]]
end


# does run_replacement with every possible stratedgy, given the faulty set
# and the possible replacement cores
#  
# nirgam      -  the path to the nirgam root directory with a '/' at the end
# tg          -  the TaskGraph file with default configuration. 
#                ex nirgam/config/traffic/App2TG
# faulty      -  faulty set from default configuration e.g. [3,27,20]
# replacement -  available replacement tiles e.g. [5,11,17,23,29]
def run_all_replacements_given_faulty(nirgam,tg,faulty,replacement)
  results = Hash.new
  mappings = get_mappings(faulty,replacement)
  count = 1
  mappings.each do |map|
    puts "Progress: #{count}/#{mappings.length}"
    count += 1
    results[map] = run_replacement(nirgam,tg,map)
  end
  return results
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

# runs nirgam using the TGN application with a given replacement
# stratedgy.
# nirgam    -  the path to the nirgam root directory with a '/' at the end
# tg        -  the TaskGraph file with default configuration. 
#              ex nirgam/config/traffic/App2TG
# stratedgy -  replacement stratedgy of the form:
#              {dtileID=>rtileID,dtileID=>ntileID}
#              where dtileID is a tileID from tg and
#              rtileID is a replacement tile.
def run_replacement(nirgam,tg,stratedgy)
  # load up tg
  task_graph = read_TG(tg)
  # swap the cores with those in stratedgy
  stratedgy.each_pair do |d,r|
    #change all the nodes
    task_graph[0].each_index do |i|
      task_graph[0][i][0] = r if task_graph[0][i][0] == d
    end
    #change all the edges
    task_graph[1].each_index do |i|
      task_graph[1][i][0] = r if task_graph[1][i][0] == d # source
      task_graph[1][i][1] = r if task_graph[1][i][1] == d # dest
    end
  end
  # write tg
  write_TG(task_graph,nirgam+"config/traffic/TGN")
  # run nirgam
  `cd #{nirgam};./nirgam`
  # get OAL
  average_latency = oal(nirgam+"results/BTY/stats/sim_results")
  # get tt_latency
  tt_latency = get_tt_latency(nirgam+"log/traffic/")
  # return [tt_latency,OAL]  
  return [average_latency,tt_latency]
end

def get_tt_latency(dir)
  result = Hash.new
  counts = Hash.new
  Dir.foreach(dir) do |item|
    if (log = /tile-(\d+)$/.match(item))
      id = log[1].to_i
      File.open(dir+item,'r').each do |line|
        match  = /^recv (\d+) (\d+) (\d+) (\d+)/.match(line)
        result[{match[1].to_i=>id}] = 0 if !result[{match[1].to_i=>id}]
        counts[{match[1].to_i=>id}] = 0 if !counts[{match[1].to_i=>id}]
        result[{match[1].to_i=>id}] += match[4].to_i
        counts[{match[1].to_i=>id}] += 1
      end
    end    
  end
  #get the averages
  result.each_pair do |key,val|
    result[key] = val/counts[key].to_f
  end
  return result
end

# averages the task-task latencies, as returned by get_tt_latency
# oal gives average per flit, this is average per link(regardless of #flits).
def average_tt_latency(tt_latency)
  result = 0
  tt_latency.each_value do |v|
    result += v/tt_latency.size.to_f
  end
  return result
end




# reads in a description of a task graph
# the format allows for a series of two directives seperated by \n:
# EDGE src_id dest_id volume
# NODE id exec
# src_id   - the parent tileID of the edge
# dest_id  - the child tileID of the edge
# volume   - the data volume(flits) transmitted from the 
#            src_id to the dest_id each execution cycle
# id       - the tileID of the node
# exec     - the execution time per cycle of the node
#
# return: an array of the form
# TG    -> [NODES,EDGES]
# NODES -> [[id,exec],[id,exec],...,[id,exec]]
# EDGES -> [[src_id,dest_id,volume],...,[src_id,dest_id,volume]]
def read_TG(infile)
  result = [Array.new,Array.new]
  File.open(infile,'r').each do |line|
    match = /^NODE (\d+) (\d+)/.match(line)
    if(match)
      result[0].push([match[1].to_i,match[2].to_i])
    end

    match = /^EDGE (\d+) (\d+) (\d+)/.match(line)
    if(match)
      result[1].push([match[1].to_i,match[2].to_i,match[3].to_i])
    end
  end
  return result
end

# does the opposite of read_TG
# tg      - a task graph as described by read_TG
# outfile - the path to write to
def write_TG(tg,outfile)
  `rm #{outfile}`
  File.open(outfile, 'w') do |out|
    tg[0].each do |node|
      out.write("NODE #{node[0]} #{node[1]}\n")
    end
    tg[1].each do |edge|
      out.write("EDGE #{edge[0]} #{edge[1]} #{edge[2]}\n")
    end
  end
end

# Overall average latency (in clock cycles per flit).
# can be found at the bottom of 
# $NIRGAM/results/$RNAME/stats/sim_results
# file:: the sim_results file to read ex: 
#        "mynirgam/results/BYT/stats/sim_results"
def oal(file)
  File.open(file).each do |line|
    regex = 
      /Overall average latency \(in clock cycles per flit\) = (\d*\.?\d+)/
    match = regex.match(line)
    return match[1].to_f if match
  end
  return nil
end
