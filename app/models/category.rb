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
  @@categories = []
  
  def Category.all
    return @@categories unless @@categories.empty?
    path = Backlog::Git.instance.git.dir.path
    categories_file = File.join(path, FILENAME)
    Category.create(categories_file) unless File.readable?(categories_file)
    File.open(categories_file) do |f|
      while line = f.gets
	line.chomp!
	next if line[0,1] == "#"
	next if line.empty?
	if line =~ /^(\S+)\s+(.*)$/
	  @@categories << Category.new($1, $2)
	else
	  $stderr.puts "Malformed line in #{categories_file}: #{line}"
	end
      end
    end
    @@categories
  end

  def Category.find id
    Category.all if @@categories.empty?
    @@categories.each do |category|
      return category if category.id == id
    end
    nil
  end

  attr_reader :dir, :prefix, :name

  def initialize dir, name
    raise "Invalid category dir #{dir}" unless dir =~ /(\w|[-_])+/
    raise "Category name must not be empty" if name.blank?
    $stderr.puts "Category.new #{dir}:>#{name}<"
    @prefix = dir
    @dir = File.join(Backlog::Git.instance.git.dir.path, dir)
    Dir.mkdir(@dir) unless File.directory?(@dir)
    @name = name
    @cache = ItemCache.new self
  end
  
  # ActiveModel helper
  def persisted?
    true
  end

  def to_s
    @name
  end

  def id
    @prefix
  end
  
  def items
    @cache.items
  end

  def delete id
    $stderr.puts "Category.delete #{id}"
    # helper for actionpack (3.0.7) lib/action_view/helpers/form_helper.rb:668:in hidden_field'
  end
  
private
  def Category.create categories_file
    $stderr.puts "Category.create #{categories_file}"
    File.open(categories_file, "w") do |f|
      f.write <<-CATEGORIES
epic Epics
story Stories
inprogess In Progress
      CATEGORIES
    end
    git = Backlog::Git.instance.git
    git.add categories_file
    git.commit "Initial set of categories"
  end
end
