require 'parsedate'
require 'active_model'
require 'lib/git'

class Item
  include ActiveModel::Validations
  include ActiveModel::Dirty
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_reader :created_by, :created_on, :description
  
  def Item.path_for subject
    File.join(File.expand_path(Backlog::Git.instance.git.dir.path), subject)
  end

  def Item.find subject
    return nil unless File.exists?(Item.path_for subject)
    Item.new subject
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
    @header = []
    @headerpos = {}
    case item
    when String
      if name[0,1] == "/"
	# read item from file
	self.read name
      elsif name.length > 0
	path = self.class.path_for name
	self.read path
	@changed = false
      else
	raise "Empty name passed to Item.new"
      end
    when IO
      read item
    else
      # New item
      self.changed!
    end
  end
  
  def changed!
    @changed = true
  end
  
  def path
    @path
  end

  def to_s
    self.subject
  end

  def save
    return unless @changed
    raise "Cannot save Item without Subject" if self.subject.to_s.empty?
    @path = self.class.path_for self.subject
    commit = nil
    File.open(@path, "w") do |f|
      if @created_by
	commit = "Updated item"
	@header.each do |l|
	  f.puts l
	end
      else
	commit = "New item"
	@created_by = ENV['USER']
	@created_on = Time.now
	# Create new file
	f.puts "From #{@created_by} #{@created_on.asctime}"
	f.puts "From: #{@created_by}"
	f.puts "Date: #{@created_on}"
	f.puts ""
      end
      f.write @description
    end
    @git.add path
    @git.commit commit
  end

  def persisted?
    true
  end

  def description
    @description
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
    unless lnum
      if setter
	# new header entry, compute @headerpos
	lnum = @header.size
	@headerpos[key] = [lnum, key.length+2]
      end
    end
    if lnum
      if setter
	$stderr.puts "Items.#{key} = #{value}"
	@header[lnum] = "#{key}: #{value}"
	value
      else
	$stderr.puts "Items.#{key} is #{@header[lnum][pos..-1]}"
	@header[lnum][pos..-1]
      end
    else
      $stderr.puts "Items.#{key} not defined"
      raise if key == "Read"
      nil
    end
  end

private
  #
  # Read item from IO or from path
  #
  def read from
    unless from.is_a? IO
      f = File.open(from)
    else
      f = from
      changed!
    end
    begin
      lnum = 0
      while line = f.gets
	@header << line.chomp!
	case line
	when /^From (\S+)\s(.*)$/
	  # 'From ' must be first line	      
	  raise "Bad file format, wrong 'From '" unless lnum == 0
#	  $stderr.puts "by >#{$1}< on >#{$2}<"
	  @created_by = $1
	  @created_on = Time.gm(*ParseDate.parsedate($2))
	when /^((\w+):\s+)(.*)$/
	  $stderr.puts "<#{$2}>[#{$3}]"
	  @headerpos[$2.capitalize] = [lnum, $1.size]
	when ""
	  # empty line, rest must be mail body
	  @description = f.read
	end
	lnum += 1
      end
      raise "Bad file format, wrong 'From ' format" unless @created_by && @created_on
    ensure
      f.close unless f == from
    end
  end
end
