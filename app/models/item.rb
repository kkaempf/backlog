require 'parsedate'
require 'active_model'
require 'lib/git'

class Item
  include ActiveModel::Validations
  include ActiveModel::Dirty
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_reader :created_by, :created_on, :persona, :title, :description
  
  def Item.find id
    return nil unless File.exists?(File.join(File.expand_path(Backlog::Git.instance.git.dir.path), id))
    Item.new id
  end

  def initialize name = nil
    @git = Backlog::Git.instance.git
    @name = name
    @header = []
    @headerpos = {}
    if name
      self.path = name
      if File.exists? @path
	File.open(@path) do |f|
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
      @title = self.header["Subject"]
      @changed = false
    else
      # New item
      @changed = true
    end
  end
  
  def to_s
    @name
  end

  def save
    return unless @changed
    unless @path
      self.name = title unless @name
      self.path = name
    end
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
	f.puts "Subject: #{@title}"
	f.puts "Date: #{@created_on}"
	f.puts ""
      end
      f.write @description
    end
    @git.add @name
    @git.commit commit
  end

  def persisted?
    true
  end

  def method_missing name, *args
    Rails.logger.info "Items.#{name.to_s} not implemented"
    $stderr.puts "Items.#{name.to_s} not implemented"
    if name.to_s[-1,1] == "="
      self.header = name, args.shift
    else
      self.header name
    end
  end

private
  def header key
    lnum, pos = @headerpos[key]
    if lnum
      @header[lnum][pos..-1]
    else
      nil
    end
  end

  def header= key, value
    lnum, pos = @headerpos[key]
    if lnum
      @header[lnum] = "#{key.capitalize}: #{value}"
    else
      nil
    end
  end

  def path= name
    @path = File.join(File.expand_path(@git.dir.path), name)
  end

  def name= n
    # normalize name
    # ...
    @name = n
  end
end
