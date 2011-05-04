#
# ItemCache - Cache of Items - per Category
#
# Not for public use - access it via Item methods
#

require 'lib/git'

class ItemCache

  SORT_ORDER_NAME = ".order"

  attr_reader :sorted

  #
  # Initialize ItemCache for items belonging to category
  #
  def initialize category
    @category = category
    @dir = category.dir
    @sorted = []
    @path = {}     # path -> item
    @subject = {}  # subject -> item

    raise "No such category dir #{@dir}" unless File.directory?(@dir)
    $stderr.puts "ItemCache.new(#{@category.name}) -> #{@dir}"

    #
    # The files define the items of the category. The .order file just adds ordering information.
    #
    files = Backlog::Git.instance.git.ls_files
    plen = @category.prefix.length
    files.each_key do |path|
      $stderr.puts "ItemCache path >#{path}< prefix [#{@category.prefix}:#{plen}>]"
      next if path[0,1] == "."
      next unless @category.prefix == path[0,plen]
      file = path[plen+1..-1] # remove dir prefix
      $stderr.puts "ItemCache file >#{file}<"
      next if file[0,1] == "."
      $stderr.puts "Filling cache with '#{file}'"
      item = Item.new category
      item.path = File.join(category.dir,file)
      @path[path] = item
    end

    # get ordering information
    read_sort_order

    raise "@path (#{@path.size} entries) and @subject (#{@subject.size} entries) inconsistent" unless @path.size == @subject.size
    
    # consistency check
    
    sorted_changed = false
    
    # Any removed files in @sorted ?
    @sorted.delete_if do |item|
      sorted_changed = true if @path[item.path].nil?
    end

    # Any new files not in @sorted ?
    if @sorted.size < @path.size
      @path.each do |path,item|
	unless @sorted.include? item
	  @sorted << item
	  sorted_changed = true
	end
      end
    end

    write_sort_order if sorted_changed

    $stderr.puts "Cache filled for #{@category}"
    $stderr.puts "#{@path.size} pathes"
    $stderr.puts "#{@subject.size} subjects"
    $stderr.puts "#{@sorted.size} sorted"
  end

  def items
    @sorted
  end

  #
  # Iterate items in sorted order
  #
  def each
    @sorted.each do |item|
      yield item
    end
  end

  def path id
    @path[id]
  end
  
  def subject s
    @subject[s]
  end

  def sorted
    @sorted
  end

  #
  # add Item
  #
  def add item
    $stderr.puts "Add #{item}"
    s = @subject[item.subject]
    raise "Subject '#{item.subject}' already exists as #{s}" if s
    @subject[item.subject] = item 
    @path[item.path] = item
    @sorted << item.path
    write_sort_order
  end

  #
  # remove Item
  #
  def remove item
    $stderr.puts "remove #{item}"
    @subject.delete item.subject
    @path.delete item.path
    @sorted.delete item
    item.delete
    write_sort_order
  end

  #
  # change subject
  # item still has old subject
  #
  def change_subject item, subject
    return unless @path[item.path]
    raise "Duplicate Subject '#{subject}'" if @subject[subject]
    @subject.delete item.subject if item.subject
    item.subject = subject
    @subject[subject] = item
  end

  #
  # sort
  #

  def sort list
    # check list for consistency
    raise "Item.sort got sort list of wrong size #{list.size}, should be #{@sorted.size}" unless list.size == @sorted.size
    list.each do |id|
      raise "Bad sort list, id #{id} does not exist" unless @path[id]
    end
    # import new sort order
    @sorted.clear
    list.each do |id|
      @sorted << path[id]
    end
    write_sort_order
  end

private
  # .sort_order is
  # <path>[<space><subject>]

  def create_sort_order
    $stderr.puts "Creating #{@dir}/#{SORT_ORDER_NAME}"
    # .sort_order not readable
    # initial sort_order creation
    @path.each_key do |path|
      item = Item.new @category
      item.path = path
      @sorted << item
      $stderr.puts "#{path} -> #{item.subject}"
      @subject[item.subject] = item
    end
    @sorted.sort!
    $stderr.puts "Created #{@sorted.size} entries for #{@dir}/#{SORT_ORDER_NAME}"
  end

  #
  # read_sort_order from @dir
  #
  def read_sort_order
    name = File.join(@dir, SORT_ORDER_NAME)
    return create_sort_order unless File.readable?(name)
    $stderr.puts "Reading #{name}"
    @sorted.clear
    File.open(name) do |f|
      while line = f.gets
	line.chomp!
	next if line[0,1] == "#"
	next if line.empty?
	if line =~ /^(\S+)(\s+(.*))?$/
	  path = $1
	  item = @path[path]
	  unless item
	    $stderr.puts "Dropping unknown path #{path} from #{name}"
	    next
	  end
	  @sorted << item
	  # capture subject if it exists
	  if $3
	    $stderr.puts "#{path}: #{$3}"
	    item.subject = $3
	  end
	  @subject[item.subject] = item
	else
	  $stderr.puts "Malformed line in #{name}: #{line}"
	end
      end
    end
  end
  
  #
  # write_sort_order
  #
  def write_sort_order
    name = File.join(@dir, SORT_ORDER_NAME)
    File.open(name, "w+") do |f|
      f.puts "# Backlog sort order"
      f.puts "# <path>[<space><subject>]"
      f.puts "#"
      f.puts "# if <subject> is missing, it will be read from <path>"
      f.puts "#"
      @sorted.each do |item|
	f.puts "#{item.path} #{item.subject}"
      end
    end
    $stderr.puts "Written #{@sorted.size} entries to #{name}"

    # update order in git
    git = git.git # Ouch!
    git.add SORT_ORDER_NAME
    status = git.status[SORT_ORDER_NAME]
    if status && status.type
      git.commit ".sort_order changed"
    end
  end

end
