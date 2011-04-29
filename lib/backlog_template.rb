#
# backlog_template
#
# A template for the header of backlog items
#
require 'lib/git'

BACKLOG_TEMPLATE_PATH = ".template"

class BacklogTemplate

  def initialize
    git = Backlog::Git.instance.git
    @path = File.join(git.dir.path,BACKLOG_TEMPLATE_PATH)
    unless File.readable?(@path)
      File.open(@path, "w+") do |f|
	f.write <<-TEMPLATE
# backlog item template
# path, subject, and description are built-in
# list here additional headers
#
# The "- " prefix is required to preserve ordering !
#
- persona: 10
- value: 5
- usecase: 50x10
	TEMPLATE
      end
      git.add BACKLOG_TEMPLATE_PATH
      git.commit("Created default .template")
    end
    File.open(@path) do |f|
      @template = YAML.load(f)
    end
  end

  def each
    @template.each { |t| yield t }
  end

end
