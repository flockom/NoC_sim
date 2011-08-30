# scrape.rb
# Author: Frank Lockom

# handles file IO associated with tgff

#TODO: add support for multiple task graphs in one file?? when its useful.




# reads in a tgff file generated by the 
# tgff configuration file currently named "t1.tgffopt"
# which generates a task graph and two tables
#
# the first table called "EXEC" associates with each node(task) type
# an exec_time which is the number of cycles in nirgam
# that the task takes to complete.
#
# the second table called "VOLUME" associates with each edge the data
# volume which is transfered on the edge once the task completes execution.
#
# infile is the path of the .tgff file to read
# returns a task graph in the format described in scrape.rb:read_TG
def read_tgff(infile)
  result  = [Array.new,Array.new]
  task_type = Hash.new
  edge_index = Hash.new
  edge_type = Hash.new
  exec = Hash.new
  vol  = Hash.new
  s = 0
  graph = File.open(infile,'r').each do |line|
    case s
      when 0
        s = 1 if /@TASK_GRAPH \s+ 0 \s+ {/x.match line
        s = 2 if /@EXEC \s+ 0 \s+ {/x.match line
        s = 3 if /@VOLUME \s+ 0 \s+ {/x.match line
      when 1 # in TASK_GRAPH
        s = 0 if /}/.match line
      
        # add task
        if (m = /TASK \s+ t0_(\d+) \s+ TYPE \s+ (\d+)/x.match line)
          result[0].push [m[1].to_i,-1] # add the task, don't have the execution time yet(-1)
          task_type[m[1].to_i] = m[2].to_i  # map task to task type
        end

        # add edge
        if (m = /ARC \s+ a0_(\d+) \s+ FROM  \s+ t0_(\d+) \s+ TO \s+ t0_(\d+) \s+ TYPE \s+ (\d+)/x.match line)
          result[1].push [m[2].to_i,m[3].to_i,-1] # dont have volume yet(-1)
          edge_index[[m[2].to_i,m[3].to_i]] = m[1].to_i # map edge [src,dst] to edge index
          edge_type[m[1].to_i] = m[4].to_i  # map edge index to edge type
        end

      when 2 # in EXEC
        s = 0 if /}/.match line
        if (m = /(\d+) \s+ (\d+) \s+ (\d+)/x.match line)
          exec[m[1].to_i] = m[3].to_i # map task type to execution time
        end

      when 3 # in VOLUME
        s = 0 if /}/.match line
        if (m = /(\d+) \s+ (\d+)/x.match line)
          vol[m[1].to_i] = m[2].to_i # map edge type to volume
        end
    end
  end  
  
  # now fill in the execution times and volumes
  result[0].each do |t|
    t[1] = exec[task_type[t[0]]]
  end
  result[1].each do |e|
    e[2] = vol[edge_type[edge_index[[e[0],e[1]]]]]
  end

  result

end



# uses TGFF to generate a random task graph in the format 
# described in scrape.rb:read_TG.
# This uses the "old algorithm" as refered to in the tgff documentation
# a notable parameter which is left out is
# the maximum in/out degree on nodes. Could me added
# if more control of the graph structure is desired
# also could consider a different function which uses the "new algorithm"
# which allows for even more control of the graph's structure.
#
# All of the parameters share the same name as those used in tgff where applicable
# 
# seed            - the random seed for tgff (integer) 
# task_cnt          - number of tasks in the graph (+/- 1) 
# task_type_cnt   - 1 means all tasks have same execution time, 
#                   num_taks means the (could) all be different
# trans_type_cnt  - 1 means all edges have the same volume
# avg_exec_time   - execution time is random: [-1,1)*exec_time_mult + avg_exec_time
# exec_time_mult  - see avg_exec_time
# avg_volume      - see avg_exec_time
# volume_mult     - ^^^ get it yet?
#
def generate_tg(seed,task_cnt,task_type_cnt,trans_type_cnt,
                avg_exec_time,exec_time_mult,
                avg_volume,volume_mult)

  tgffopt = <<END
# general tgff options
seed #{seed}
tg_cnt #{1}
task_cnt #{task_cnt} 1
period_mul #{1}
task_type_cnt #{task_type_cnt}
trans_type_cnt #{trans_type_cnt}

# create the execution time table
table_label EXEC
table_cnt 1
table_attrib
type_attrib exec_time #{avg_exec_time} #{exec_time_mult} 0 1
pe_write

# create the volume table
table_label VOLUME
table_cnt 1
type_attrib volume #{avg_volume} #{volume_mult} 0 1
trans_write

#output the graph
tg_write

END

  File.open('./temp.tgffopt','w') {|f| f.write(tgffopt)}
  `tgff temp`
  result = read_tgff('temp.tgff')
  
  `rm ./temp.tgffopt`
  `rm ./temp.tgff`

  result

end
