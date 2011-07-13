# scrape.rb
# Author: Frank Lockom
# handles file IO associated with nirgam

# reads in a description of a task graph
# the format allows for a series of two directives seperated by \n:
# EDGE src_id dest_id volume
# NODE id exec
# line comments can be inserted using #
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

# gets the average per flit latency for every traffic log file in dir
# typicall dir is 'nirgam/log/traffic/'
# it will contain a tile-n file for every task in the last run of the TGN application.
#
# dir must contain only the traffic log files from the most recent nirgam run.
# the driver will delete the old files before running nirgam but you must delete them manually
# if you do not use the driver.
def get_average_tt_latency(dir)
  result = Hash.new
  counts = Hash.new
  Dir.foreach(dir) do |item|
    if (log = /tile-(\d+)$/.match(item))
      id = log[1].to_i
      File.open(dir+item,'r').each do |line|
        if (match  = /^recv (\d+) (\d+) (\d+) (\d+)/.match(line))
          result[{match[1].to_i=>id}] = 0 if !result[{match[1].to_i=>id}]
          counts[{match[1].to_i=>id}] = 0 if !counts[{match[1].to_i=>id}]
          result[{match[1].to_i=>id}] += match[4].to_i
          counts[{match[1].to_i=>id}] += 1
        end
      end
    end    
  end
  #get the averages
  result.each_pair do |key,val|
    result[key] = val/counts[key].to_f
  end
  return result
end


def get_tt_average_comm_time(dir)
  result = Hash.new
  counts = Hash.new
  Dir.foreach(dir) do |item|
    if (log = /tile-(\d+)$/.match(item))
      id = log[1].to_i
      File.open(dir+item,'r').each do |line|
        if (match  = /^communication_time (\d+) on period (\d+) from tile (\d+)/.match(line))
          result[{match[3].to_i=>id}] = 0 if !result[{match[3].to_i=>id}]
          counts[{match[3].to_i=>id}] = 0 if !counts[{match[3].to_i=>id}]
          result[{match[3].to_i=>id}] += match[1].to_i
          counts[{match[3].to_i=>id}] += 1
        end
      end
    end    
  end
  #get the averages
  result.each_pair do |key,val|
    result[key] = val/counts[key].to_f
  end
  return result
end
