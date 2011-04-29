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
  # Initialize ItemCache for items below path (== category)
  #
  def initialize prefix
    @prefix = prefix
    @sorted = []
    @path = {}     # path -> nil|""|item|subject
    @subject = {}  # subject -> item|path

    dir = File.join(Backlog::Git.instance.git.dir.path, prefix)
    raise "No such category dir" unless File.directory?(dir)

    # limit ls-files to category
    #
    Dir.chdir(dir) do |x|
      #
      # The files define the items of the category. The .order file just adds ordering information.
      #
      files = Backlog::Git.instance.git.ls_files
      files.each_key do |file|
	next if file[0,1] == "."
	$stderr.puts "Filling cache with '#{file}'"
	@path[file] = ""
      end
      read_sort_order
    end
    
    # fill subject if needed
    @path.each do |p,s|
      if s.empty?
	item = Item.new p, dir
	@path[p] = item
	@subject[item.subject] = item
      end
    end

    raise "@path (#{@path.size} entries) and @subject (#{@subject.size} entries) inconsistent" unless @path.size == @subject.size
    
    # consistency check
    
    sorted_changed = false
    
    # Any removed files in @sorted ?
    @sorted.delete_if do |p|
      sorted_changed = true if @path[p].nil?
    end

    # Any new files not in @sorted ?
    if @sorted.size < @path.size
      @path.each_key do |p|
	unless @sorted.include? p
	  @sorted << p
	  sorted_changed = true
	end
      end
    end

    write_sort_order if sorted_changed

    $stderr.puts "Cache filled for #{prefix}"
    $stderr.puts "#{@path.size} pathes"
    $stderr.puts "#{@subject.size} subjects"
    $stderr.puts "#{@sorted.size} sorted"
  end

  #
  # Iterate items as path,subject
  #
  def each
    @sorted.each do |path|
      p = @path[path]
      if p.is_a? Item
	yield path, p.subject
      else
	yield path, p
      end
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
  # add Item or File
  #
  def add item_or_path
    $stderr.puts "Add #{item_or_path}"
    if item_or_path.is_a? Item
      item = item_or_path
    else
      item = Item.new item.to_s, @prefix
    end
    s = @subject[item.subject]
    raise "Subject '#{item.subject}' already exists as #{s}" if s
    @subject[item.subject] = item 
    @path[item.path] = item
    @sorted << item.path
    write_sort_order
  end

  #
  # remove (path or item)
  #
  def remove item_or_path
    $stderr.puts "remove #{item_or_path}"
    if item_or_path.is_a? Item
      path = item_or_path.path
      @subject.delete item.subject
    else
      path = item_or_path
      @subject.delete path
    end

    @sorted.delete path
    @path.delete path
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
      @sorted << id
    end
    write_sort_order
  end

private
  # .sort_order is
  # <path>[<space><subject>]

  def create_sort_order
    $stderr.puts "Creating #{SORT_ORDER_NAME}"
    # .sort_order not readable
    # initial sort_order creation
    @path.each_key do |path|
      @sorted << path
      item = Item.new path
      @subject[item.subject] = item
      @path[path] = item
    end
    @sorted.sort!
    $stderr.puts "Created #{@sorted.size} entries for #{SORT_ORDER_NAME}"
  end

  #
  # read_sort_order from current directory
  #
  def read_sort_order
    return create_sort_order unless File.readable?(SORT_ORDER_NAME)
    $stderr.puts "Reading #{SORT_ORDER_NAME}"
    @sorted.clear
    File.open(sort_order_file) do |f|
      while line = f.gets
	line.chomp!
	next if line[0,1] == "#"
	next if line.empty?
	if line =~ /^(\S+)(\s+(.*))?$/
	  path = $1
	  unless @path[path]
	    $stderr.puts "Dropping unknown path #{path} from #{SORT_ORDER_NAME}"
	    next
	  end
	  @sorted << path
	  # capture subject if it exists
	  if $3
	    $stderr.puts "#{path}: #{$3}"
	    @subject[$3] = path
	    @path[path] = $3
	  else
	    item = Item.new path
	    @subject[item.subject] = item
	    @path[path] = item
	  end
	else
	  $stderr.puts "Malformed line in #{SORT_ORDER_NAME}: #{line}"
	end
      end
    end
  end
  
  #
  # write_sort_order
  #
  def write_sort_order
    git = Git.instance.git
    Dir.chdir(File.join(git.dir.path, @prefix)) do |d|
      File.open(SORT_ORDER_NAME, "w+") do |f|
	f.puts "# Backlog sort order"
	f.puts "# <path>[<space><subject>]"
	f.puts "#"
	f.puts "# if <subject> is missing, it will be read from <path>"
	f.puts "#"
	@sorted.each do |path|
	  s = @path[path]
	  raise "@sorted inconsistent for #{@prefix}/#{path}" if p.nil?
	  s = s.subject if s.is_a? Item
	  f.puts "#{path} #{s}"
	end
      end
      $stderr.puts "Written #{@sorted.size} entries to #{SORT_ORDER_NAME}"

      # update order in git
      git = git.git # Ouch!
      git.add SORT_ORDER_NAME
      status = git.status[SORT_ORDER_NAME]
      if status && status.type
	git.commit ".sort_order changed"
      end
    end
  end

end
