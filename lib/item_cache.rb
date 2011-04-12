#
# ItemCache - Cache of Item
#
# Not for public use - access it via Item methods
#

require 'lib/git'

class ItemCache
  
  SORT_ORDER_NAME = ".sort_order"
  @@fill_in_progress = false
  @@sorted = []
  @@uuid = {}
  @@subject = {}

  def ItemCache.uuid id
    ItemCache.fill_cache
    @@uuid[id]
  end
  
  def ItemCache.subject s
    ItemCache.fill_cache
    @@subject[s]
  end

  def ItemCache.sorted
    ItemCache.fill_cache
    @@sorted
  end

  #
  # add Item
  #
  def ItemCache.add item
    ItemCache.fill_cache
    $stderr.puts "Adding '#{item.uuid}' to cache: #{item.subject}"
    uuid = item.uuid
    if @@uuid[uuid]
      raise "Item '#{uuid}' already exists as #{@@uuid[uuid]}" unless @@fill_in_progress
    end
    if item.subject
      if @@subject[item.subject]
	raise "Subject '#{item.subject}' already exists as #{@@subject[item.subject].uuid}" unless @@fill_in_progress
      end
      @@subject[item.subject] = item 
    end
    @@uuid[uuid] = item
    @@sorted << uuid
    ItemCache.write_sort_order
  end

  #
  # remove (uuid or item)
  #
  def ItemCache.remove item
    ItemCache.fill_cache
    if item.is_a? Symbol
      item = @@uuid[item]
    end
    $stderr.puts "Item.remove #{item}"
    uuid = item.uuid

    @@sorted.delete uuid
    @@uuid.delete uuid
    @@subject.delete item.subject
    ItemCache.write_sort_order
  end

  #
  # change subject
  # item still has old subject
  #
  def ItemCache.change_subject item, subject
    ItemCache.fill_cache
    return unless @@uuid[item.uuid]
    raise "Duplicate Subject '#{subject}'" if @@subject[subject]
    @@subject.delete item.subject if item.subject
    @@subject[subject] = item
  end

  #
  # sort
  #

  def ItemCache.sort list
    ItemCache.fill_cache
    # check list for consistency
    raise "Item.sort got sort list of wrong size #{list.size}, should be #{@@sorted.size}" unless list.size == @@sorted.size
    list.each do |uuid|
      raise "Bad sort list, uuid #{uuid} does not exist" unless @@uuid[uuid.to_sym]
    end
    # import new sort order
    @@sorted.clear
    list.each do |uuid|
      @@sorted << uuid.to_sym
    end
    ItemCache.write_sort_order
  end

private
  # .sort_order is
  # <uuid><space><subject>

  #
  # read_sort_order
  #
  def ItemCache.read_sort_order
    sort_order_file = Backlog::Git.instance.path_for SORT_ORDER_NAME
    if File.readable? sort_order_file
      $stderr.puts "Reading #{SORT_ORDER_NAME}"
      @@sorted.clear
      File.open(sort_order_file) do |f|
	while line = f.gets
	  line.chomp!
	  next if line[0,1] == "#"
	  next if line.empty?
	  if line =~ /^(\S+)\s+(.*)$/
	    uuid = $1.to_sym
	    raise "Unknown uuid #{uuid} in #{SORT_ORDER_NAME}" unless @@uuid[uuid]
	    $stderr.puts "#{uuid} #{$2}"
	    @@sorted << uuid
	  else
	    $stderr.puts "Malformed line in #{SORT_ORDER_NAME}: #{line}"
	  end
	end
      end
      $stderr.puts "Read #{@@sorted.size} entries from #{SORT_ORDER_NAME}"
    else
      $stderr.puts "Creating #{SORT_ORDER_NAME}"
      # .sort_order not readable
      # initial sort_order creation
      @@uuid.each_key do |uuid|
	@@sorted << uuid
      end
      $stderr.puts "Created #{@@sorted.size} entries for #{SORT_ORDER_NAME}"
      ItemCache.write_sort_order
    end
  end
  
  #
  # write_sort_order
  #
  def ItemCache.write_sort_order
    git = Backlog::Git.instance
    sort_order_file = git.path_for SORT_ORDER_NAME
    File.open(sort_order_file, "w+") do |f|
      f.puts "# Backlog sort order"
      f.puts "# <uuid><space><subject>"
      f.puts "#"
      f.puts "# !! <subject> is just for humans, only <uuid> is relevant"
      f.puts "#"
      @@sorted.each do |uuid|
	f.puts "#{uuid} #{@@uuid[uuid].subject}"
      end
      $stderr.puts "Written #{@@sorted.size} entries to #{SORT_ORDER_NAME}"
    end
    git = git.git # Ouch!
    git.add SORT_ORDER_NAME
    status = git.status[SORT_ORDER_NAME]
    if status && status.type
      git.commit ".sort_order changed"
    end
 end

  #
  # fill_cache
  #
  
  def ItemCache.fill_cache
    return if @@fill_in_progress
    return unless @@sorted.empty?
    @@fill_in_progress = true
    files = Backlog::Git.instance.git.ls_files || []
    files.each_key do |file|
      next if file[0,1] == "."
      $stderr.puts "Filling cache with '#{file}'"
      self.add Item.new(file)
    end
    self.read_sort_order
    @@fill_in_progress = false
    $stderr.puts "Cache filled"
    $stderr.puts "#{@@uuid.size} uuids"
    $stderr.puts "#{@@subject.size} subjects"
    $stderr.puts "#{@@sorted.size} sorted"
  end

end
