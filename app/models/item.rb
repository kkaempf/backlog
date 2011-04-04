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

  def initialize subject = nil
    @git = Backlog::Git.instance.git
    @header = []
    @headerpos = {}
    if subject
      path = self.class.path_for subject
      if File.exists? path
	File.open(path) do |f|
	  lnum = 0
	  while line = f.gets
	    @header << line
	    case line
	    when /^From (\S+)\s(.*)$/
	      # 'From ' must be first line	      
	      raise "Bad file format, wrong 'From '" unless lnum == 0
	      @created_by = $1
	      @created_on = Time.gm(ParseDate.parsedate($2, true))
	    when /^(\w+):\s+(.*)$/
	      $stderr.puts "<#{$1}>[#{$2}]"
	      @headerpos[$1.capitalize] = [lnum, line.size - $2.size]
	    when ""
	      # empty line, rest must be mail body
	      @description = f.read
	    end
	    lnum += 1
	  end
	  raise "Bad file format, wrong 'From ' format" unless @created_by && @created_on
	end
      end
      @changed = false
    else
      # New item
      @changed = true
    end
  end
  
  def to_s
    self.subject
  end

  def save
    return unless @changed
    raise "Cannot save Item without Subject" if self.subject.to_s.empty?
    path = self.class.path_for self.subject
    commit = nil
    File.open(path, "w") do |f|
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
      nil
    end
  end

end
