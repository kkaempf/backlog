require 'parsedate'
require 'active_model'
require 'lib/git'
require 'simple_uuid'

class Item
  include ActiveModel::Validations
  include ActiveModel::Dirty
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  @@sorted = []

  attr_reader :created_by, :created_on, :description
  
  def Item.full_path_for subject
    File.join(Backlog::Git.instance.git.dir.path, subject)
  end

  def Item.sort list
    @@sorted = list
  end

  def Item.remove id
    $stderr.puts "Item.remove #{id}"
    git = Backlog::Git.instance.git
    files = git.ls_files || []
    files.each_key do |file|
      next if file[0,1] == "."
      item = Item.new(file)
#      $stderr.puts "#{item.id}:#{item}"
      if item.id == id
	$stderr.puts "Item.remove! #{file}"
	git.remove file
	git.commit "Removed by #{ENV['USER']} on #{Time.now}"
	return true
      end
    end
    nil
  end

  def Item.find_by_id id
    files = Backlog::Git.instance.git.ls_files || []
    files.each_key do |file|
      next if file[0,1] == "."
      item = Item.new(file)
#      $stderr.puts "#{item.id}:#{item}"
      return item if item.id == id
    end
    nil
  end

  def Item.find what
    case what
    when String
      return nil unless File.exists?(Item.full_path_for what)
      Item.new subject
    when Hash
      id = what[:id]
      if id
	Item.find_by_id id
      else
	nil
      end
    when :all
      items = {}
      files = Backlog::Git.instance.git.ls_files || []
      files.each_key do |file|
	next if file[0,1] == "."
	item = Item.new(file)
	items[item.id] = item
      end
      result = []
      if @@sorted.size > 0
	@@sorted.each do |key|
	  item = items[key]
	  if item
	    result << item
	    items.delete key
	  end
	end
      end
      items.each_value do |item|
	result << item
      end
      result
    else
      nil
    end
  end

  #
  # Create Item
  # name:
  #   if nil => create new (and empty) item
  #   if File.readable? => read new item from file
  #   else => use as name of existing item
  # 
  def initialize item = nil
    @git = Backlog::Git.instance.git
    #
    # array of header lines
    @header = []
    #
    # hash of header keys => [ index into @header, start pos of value ]
    @headerpos = {}
    
    #
    #  read item properties
    read item unless item.nil?
    if self.uuid.nil?
      self.uuid = SimpleUUID::UUID.new.to_guid
    end
  end

  def id
    self.uuid
  end

  def to_s
    self.subject || self.id
  end

  def save
    file = Item.full_path_for(self.subject)
    File.open(file, "w") do |f|
      if @created_on.nil?
	@created_by = ENV['USER']
	@created_on = Time.now
	@header.push "From: #{@created_by}"
	@header.push "Date: #{@created_on}"
      end
      f.puts "From #{@created_by} #{@created_on.asctime}"
      @header.each do |l|
	f.puts l
      end
      f.puts ""
      f.write @description
    end
    @git.add file
    status = @git.status[self.subject]
    return nil unless status
    commit_msg = nil
    case status.type
    when 'A': commit_msg = "New item"
    when 'M': commit_msg = "Modified item"
    when 'D': commit_msg = "Dropped item"
    end
    return nil if commit_msg.nil?
    @git.commit commit_msg 
    file
  end

  def persisted?
    true
  end

  def description= d
    @description = d
  end

  def method_missing name, *args
    setter = false
    name = name.to_s
    # getter or setter called ?
    if name[-1,1] == "="
      key = name[0...-1]
      value = args.shift
      setter = true
    else
      key = name
    end
    # known header ?
    key = key.capitalize
    lnum, pos = @headerpos[key]
#    $stderr.puts "method_missing >#{name}<[#{key}] @ l#{lnum} p#{pos}"
    unless lnum
      if setter
	# new header entry, compute @headerpos
	lnum = @header.size
	pos = key.length+2
	@headerpos[key] = [lnum, pos]
#	$stderr.puts "New header[#{lnum}] #{key}"
      end
    end
    if lnum
      if setter
	if @header[lnum] && (@header[lnum][pos..-1] == value)
	  return
	end
#	$stderr.puts "Items.#{key} = #{value}"
	@header[lnum] = "#{key}: #{value}"
	return value
      else
#	$stderr.puts "Items.#{key} is #{@header[lnum][pos..-1]}"
	return @header[lnum][pos..-1]
      end
    else
#      $stderr.puts "Items.#{key} not defined"
      nil
    end
  end

private
  #
  # Read item from IO or from path
  #
  def read from
    if from.is_a? IO
      f = from
    else
      path = Item.full_path_for from
      return unless File.readable?(path) # new file
      f = File.open(path)
#      $stderr.puts "Item.read #{from} #{path}"
    end
    begin
      lnum = 0
      while line = f.gets
	case line.chomp
	when /^From (\S+)\s(.*)$/
	  # 'From ' must be first line	      
	  raise "Bad file format, 'From ' at line #{lnum} in #{from}" unless lnum == 0
#	  $stderr.puts "by >#{$1}< on >#{$2}<"
	  @created_by = $1
	  @created_on = Time.gm(*ParseDate.parsedate($2))
	when /^((\w+):\s+)(.*)$/
	  @header << line.chomp!
#	  $stderr.puts "<#{$2}>[#{$3}]"
	  @headerpos[$2.capitalize] = [@header.size-1, $1.size]
	when ""
	  # empty line, rest must be mail body
	  self.description = f.read
	end
	lnum += 1
      end
      raise "Bad file format, wrong 'From ' format in #{from}" if @created_by.nil? || @created_on.nil?
    ensure
      f.close unless f == from
    end
  end
end
