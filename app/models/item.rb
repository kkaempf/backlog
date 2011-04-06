require 'parsedate'
require 'active_model'
require 'lib/git'

class Item
  include ActiveModel::Validations
  include ActiveModel::Dirty
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_reader :created_by, :created_on, :description
  
  def Item.full_path_for subject
    File.join(Backlog::Git.instance.git.dir.path, subject)
  end

  def Item.find what
    case what
    when String
      return nil unless File.exists?(Item.full_path_for subject)
      Item.new subject
    when :all
      files = []
      @git.status.each do |file|
	files << file
      end
      files
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
    @header = []
    @headerpos = {}
    read item unless item.nil?
  end
  
  def changed?
    $stderr.puts "Changed? #{@git.status.pretty}"
    status = @git.status[self.subject]
    $stderr.puts "u>#{status.untracked.inspect}< t>#{status.type.inspect}<" if status
    return true if status.nil? || status.untracked || status.type
    false
  end

  def to_s
    self.subject
  end

  def save
    return unless changed?
    commit = nil
    file = Item.full_path_for(self.subject)
    File.open(file, "w") do |f|
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
    @git.add file
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
    name = name[1..-1] if name[0,1] == "@"
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
    if from.is_a? IO
      f = from
    else
      f = File.open(Item.full_path_for from)
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
