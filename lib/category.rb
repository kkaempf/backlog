#
# Category - backlog item category
#
require 'lib/git'
require 'lib/item_cache'

class Category
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

  attr_reader :dir, :name, :items

  def initialize dir, name
    $stderr.puts "Category.new #{dir}:#{name}"
    @dir = dir
    Dir.mkdir(dir) unless File.directory?(dir)
    @name = name
    @items = ItemCache.new dir
  end
  
  def id
    @dir
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
