#
# Item - Backlog item
#
#

require 'parsedate'
require 'active_model'
require 'lib/git'
require 'lib/item_cache'
require 'simple_uuid'

class Item
  include ActiveModel::Validations
  include ActiveModel::Dirty
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  attr_reader :created_by, :created_on, :subject, :uuid, :description

  validates_each :subject do |record, attr, value|
    record.errors.add attr, "missing" unless record.subject && record.subject.size > 0
  end

############################################################################
# Class functions

  #
  # full_path_for
  #

  def Item.full_path_for subject
    Backlog::Git.instance.path_for subject
  end

  #
  # find
  #

  def Item.find what
    case what
    when String
      return nil unless File.exists?(Item.full_path_for what)
      ItemCache.subject(subject) || Item.new(subject)
    when Hash
      id = what[:id]
      if id
	ItemCache.uuid id
      else
	nil
      end
    when :all
      # return all items in sorted order
      items = []
      ItemCache.sorted.each do |uuid|
	items << ItemCache.uuid(uuid)
      end
      items
    else
      nil
    end
  end

############################################################################
# Object functions

  #
  # Create Item
  # name:
  #   if nil => create new (and empty) item
  #   if File.readable? => read new item from file
  #   else => use as name of existing item
  # 
  def initialize item = nil
    #
    # array of header lines
    @header = []
    #
    # hash of header keys => [ index into @header, start pos of value ]
    @headerpos = {}
    
    #
    #  read item properties
    read item unless item.nil?
    if @uuid.nil?
      # new item
      self.uuid = SimpleUUID::UUID.new.to_guid.to_sym
    end
    ItemCache.add(self) 
  end

  def id
    @uuid.to_s
  end

  def to_s
    @subject || self.id
  end

  def subject= subject
#    $stderr.puts "#{item}.subject = #{subject}"
    ItemCache.change_subject self, subject
    @subject = subject
  end

  def save
    return false unless self.valid?
    file = Item.full_path_for(@subject)
    File.open(file, "w") do |f|
      if @created_on.nil?
	@created_by = ENV['USER']
	@created_on = Time.now
	@header.push "From: #{@created_by}"
	@header.push "Date: #{@created_on}"
      end
      f.puts "From #{@created_by} #{@created_on.asctime}"
      @header.push "Uuid: #{@uuid}"
      @header.push "Subject: #{@subject}"
      @header.each do |l|
	f.puts l
      end
      f.puts ""
      f.write @description
    end
    git = Backlog::Git.instance.git
    git.add file
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
  def uuid= uuid
    @uuid = uuid.to_sym
  end

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
	  key = $2.capitalize
#	  $stderr.puts "Key '#{key}':#{$3}"
	  case key
	  when "Uuid": self.uuid = $3
	  when "Subject": self.subject = $3
	  else
	    @header << $&
	    #	  $stderr.puts "<#{$2}>[#{$3}]"
	    @headerpos[$2.capitalize] = [@header.size-1, $1.size]
	  end
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
