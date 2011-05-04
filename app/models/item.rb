#
# Item - Backlog item
#
#

require 'parsedate'
require 'active_model'
require 'lib/git'

class Item
  include ActiveModel::Validations
  include ActiveModel::Dirty
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_reader :created_by, :created_on, :path

  validates_each :subject do |record, attr, value|
    record.errors.add attr, "missing" unless record.subject && record.subject.size > 0
  end

############################################################################
# private functions
private
  #
  # Read item from path
  #
  def read
    raise "Item.read without path" unless @path
    raise "File #{@path} unreadable" unless File.readable?(@path)
    $stderr.puts "Item.read(#{@path})"
    File.open(@path) do |f|
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
	  key = $2.capitalize
#	  $stderr.puts "Key '#{key}':#{$3}"
	  case key
	  when "Subject": @subject = $3
	  else
	    @header << $&
	    #	  $stderr.puts "<#{$2}>[#{$3}]"
	    @headerpos[$2.capitalize] = [@header.size-1, $1.size]
	  end
	when ""
	  # empty line, rest must be mail body
	  @description = f.read
	end
	lnum += 1
      end
      raise "Bad file format, wrong 'From ' format in #{from}" if @created_by.nil? || @created_on.nil?
    end
  end
public

############################################################################
# Object functions

  #
  # Create Item in Category
  # 
  def initialize category
    #
    # array of header lines
    @header = []
    #
    # hash of header keys => [ index into @header, start pos of value ]
    @headerpos = {}
    
    @category = category

  end

  def <=> item
    self.to_s <=> item.to_s
  end

  # helper for ActiveModel, give the model an 'id'
  def id
    raise "Item.id not set" unless @id
    $stderr.puts "Item.id >#{@id}<"
    @id
  end

  def to_s
    @subject || @id
  end

  def path= path
    @path = path
    @id = path.tr(" /", "_-")
  end

  def path
    @path ||= File.join(@category.dir, @id)
  end

  def subject= subject
    @subject = subject
    @id ||= subject.tr(" /", "_-")
  end

  def subject
    unless @subject
      read if @header.empty?
    end
    @subject
  end

  def save
    $stderr.puts "Item.save"
    return false unless self.valid?
    $stderr.puts "Item is valid"
    unless @created_by # new item
      @created_by = ENV['USER']
      @header.push "From: #{@created_by}"
      @created_on = Time.now
      @header.push "Date: #{@created_on}"
      @header.push "Subject: #{@subject}"
    end
    $stderr.puts "Item @header #{@header.inspect}"
    # use self.path to force creation of @path
    File.open(self.path, "w") do |f|
      $stderr.puts "Item.save to #{@path}"
      f.puts "From #{@created_by} #{@created_on.asctime}"
      @header.each do |l|
	f.puts l
      end
      f.puts ""
      f.write @description
    end
    git = Backlog::Git.instance.git
    git.add @path
    status = git.status[@subject]
    return nil unless status
    commit_msg = nil
    case status.type
    when 'A': commit_msg = "New item"
    when 'M': commit_msg = "Modified item"
    end
    return nil if commit_msg.nil?
    git.commit commit_msg 
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
      read if @path && @header.empty?
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

end
