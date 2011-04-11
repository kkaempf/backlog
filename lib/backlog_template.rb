#
# backlog_template
#
# A template for the header of backlog items
#
require 'lib/git'

BACKLOG_TEMPLATE_PATH = ".template"

class BacklogTemplate

  def initialize
    @path = Backlog::Git.instance.path_for(BACKLOG_TEMPLATE_PATH)
    unless File.readable?(@path)
      File.open(@path, "w+") do |f|
	f.write <<-TEMPLATE
# backlog item template
# subject, uuid, and description are built-in
# list here additional headers
#
# The "- " prefi is required to preserve ordering !
#
- persona: 10
- value: 5
- usecase: 50x10
	TEMPLATE
      end
      git = Backlog::Git.instance.git
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
