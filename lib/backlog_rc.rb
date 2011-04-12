require 'yaml'
require 'singleton'

BACKLOGRC_PATH = "~/.backlogrc"
class BacklogRc
  include Singleton

  attr_reader :home, :name, :email, :path, :origin

  def initialize
    @path = File.expand_path(BACKLOGRC_PATH)
    begin
      File.open(@path) do |f|
	rc = YAML.load(f)
	self.home = rc["home"]
	self.name = rc["name"]
	self.email = rc["email"]
	self.origin = rc["origin"]
      end
    rescue
      Rails.logger.warn "~/.backlogrc not readable"
    end
    self.home = File.expand_path(@home || "~/backlog")
  end

  def home= homedir
    Dir.mkdir(homedir) unless File.directory? homedir
    @home = homedir
  end
end
