
#I assume right column redundant cores
#
#row rippling and column stealing algorithm as I understand it -
#attempt 1.moves up/down the rows first performs row rippling. Then
#performs column stealing, stealing cores in the opposite direction of
#movement, if they are available the the row directly adjacent to the
#current core. When getting to the bottom/top the direction changes.
#keeps moving up and down until all fauly cores have been mapped.

# full row rippling -

# partial row rippling - 

# column stealing -

# tg           - the task graph with default mapping
# faulty       - array of faulty cores in tg
# replacements - array of possible replacement cores 
# cols            - n column mesh
def rrcs_1(tg,faulty,replacements,cols)

  #first determine the number of rows by the greatest row which a task
  # is mapped to or in which a replacement/faulty core exists.
  task_max,trash = tg[0].max_by{|a| a[0]}
  repl_max = [replacements,faulty].flatten.max
  rows = ([task_max,repl_max].max / cols.to_f).ceil

  # create the inital mapping from virtual cores to physical cores.
  # leave faulty cores null
  mapping = Hash.new
  (rows*cols).times {|i| mapping[i] = (faulty.include?(i))?("faulty"):i}

#  puts "\n\n\n #{mapping}"
  #move down and up the rows until all rows are reconfigured.
  finished = Array.new(rows){|i| false}
  row = 0
  direction = false # false - down, true - up
  while( !finished.reduce(true){|all,i|all && i}) do
#    puts "\n\n row #{row}"

#    puts mapping
#    puts "row rippling "    
    row_rippling1(mapping,row,replacements,cols)

#    puts mapping

#    puts "column stealing "
    finished[row] = column_stealing1(mapping,row,replacements,cols,direction)
#    puts mapping
    
    # go to next row
    if direction # going up      
      row -= 1
      if row==0 # switch to down
        direction=false 
      else
      end              
    else # going down      
      row +=1
      if row == rows-1 # switch to up
        direction=true
      end
    end

  end
  mapping
end




#moves cores to left (assuming we have right column redundant) from
#the left.  it will start from the num_faulty-num_repl+1st faulty core
#from the right(or the first one).  
#i.e. X12R -> 12RX , X1X34R -> X134RX, X12XX5RR -> X125RRXX
#
# mapping      - Hash mapping each virtual core to a physical core, 
#                 if there is no mapping it is nil
# row          - the row being worked on, 0 indexed
# replacements - redundant cores, do not need to be mapped
# cols         - number of columns in the mesh
# OUTPUT: modifies the mapping to reflect the row rippling.
#         returns true if the row is finished.
def row_rippling1(mapping,row, replacements,cols)   

  # determine # of replacement cores in row
  # determine # of faulty cores in row
  n_repl = 0  
  n_faulty = 0
  (row*cols...row*cols+cols).each do |i|
    n_repl +=1  if replacements.include?(i)
    n_faulty+=1 if mapping[i] == "faulty"
  end

  if(n_faulty == 0)
    return true
  end


  # position over the n_faulty-n_repl faulty core if we don't have enough
  # otherwise start at the first one
  if n_faulty > n_repl
    offset = n_faulty - n_repl + 1
    enough = true
  else
    offset = 1
    enough = false
  end
  
  #move to the offset fauly core from the left
  i=0
  current = row*cols
  while true do
    if mapping[current] == "faulty"
      i+=1
      break if i == offset
    end
    current +=1
  end
  
  # ripple cores to the left from current
  marker = current+1
  while marker < row*cols+cols do
    if mapping[marker] == "faulty" #move to next core
      marker+=1
    else                           # move this core left      
      mapping[current] = mapping[marker]
      current+=1
      # if mapping[marker] == nil
      #   puts "FUCK! #{row} #{replacements} #{cols}  #{marker} #{current}"
      #   exit
      # end

      mapping[marker]  = "faulty"
    end
  end
  return enough
end

# for each faulty core in row attempt to steal the core in the
# adjacent row in the given direction. If the core is fauly it is left
# alone.
#
# mapping      - Hash mapping each virtual core to a physical core, 
#                 if there is no mapping it is nil
# row          - the row being worked on, 0 indexed
# replacements - redundant cores, do not need to be mapped
# cols         - number of columns in the mesh
# direction    - direction to steal from, false - down, true - up
# OUTPUT: modifies mapping to reflect the column stealing
#         returns true if the row is finished
def column_stealing1(mapping,row, replacements,cols, direction)
  finished = true
  # look at each core in this row
  (row*cols...row*cols+cols).each do |i|
    if mapping[i] == "faulty" && !replacements.include?(i)
      finished = false
      #check if the adjacent core in direction is available
      steal = (direction)?(i-cols):(i+cols)
      if mapping[steal] != "faulty"
        mapping[i] = mapping[steal]
        
        # excuse my pathetic debugging
        # if mapping[steal] == nil
        #   puts "FUCK! #{row} #{replacements} #{cols} #{direction} #{i} #{steal}"
        #   exit
        # end
        mapping[steal] = "faulty"
      end
    end
  end

  return finished
end



