#
# Category - backlog item category
#

require 'lib/git'
require 'lib/item_cache'
require 'active_model'

class Category
  extend ActiveModel::Naming
  include ActiveModel::Conversion

  FILENAME = ".categories"
  
  def Category.all
    result = []
    git = Backlog::Git.instance.git
    Dir.chdir(git.dir.path) do |d|
      Category.create unless File.readable?(FILENAME)
      File.open(FILENAME) do |f|
	while line = f.gets
	  line.chomp!
	  next if line[0,1] == "#"
	  next if line.empty?
	  if line =~ /^(\S+)\s+(.*)$/
	    result << Category.new($1, $2)
	  else
	    $stderr.puts "Malformed line in #{FILENAME}: #{line}"
	  end
	end
      end
    end
    result
  end

  def Category.find id
    Category.new id, ""
  end

  attr_reader :dir, :name

  def initialize dir, name
    raise "Invalid category dir #{dir}" unless dir =~ /(\w|[-_])+/
    $stderr.puts "Category.new #{dir}:#{name}"
    @dir = dir
    Dir.mkdir(dir) unless File.directory?(dir)
    @name = name
  end
  
  # ActiveModel helper
  def persisted?
    true
  end

  def to_s
    @dir
  end

  def id
    @dir
  end
  
  def items
    @items ||= ItemCache.new(@dir)
  end

  def delete id
    $stderr.puts "Category.delete #{id}"
    # helper for actionpack (3.0.7) lib/action_view/helpers/form_helper.rb:668:in hidden_field'
  end
  
  def Category.create
    File.open(FILENAME, "w") do |f|
      f.write <<-CATEGORIES
epic Epics
story Stories
inprogess In Progress
      CATEGORIES
    end
    git = Backlog::Git.instance.git
    git.add FILENAME
    git.commit "Initial #{FILENAME}"
  end
end
