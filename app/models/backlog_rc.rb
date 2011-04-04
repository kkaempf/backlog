require 'active_model'
require 'yaml'
require 'singleton'

BACKLOGRC_PATH = "~/.backlogrc"
class BacklogRc
  include Singleton
  include ActiveModel::Validations
  extend ActiveModel::Naming

  validates :home, :presence => true
  attr_reader :name, :email, :path

  def initialize
    @path = File.expand_path(BACKLOGRC_PATH)
    begin
      File.open(@path) do |f|
	rc = YAML.load(f)
	self.home = rc["home"]
	self.name = rc["name"]
	self.email = rc["email"]
      end
    rescue
      Rails.logger.warn "~/.backlogrc not readable"
    end
    self.home = File.expand_path(@home || "~/backlog")
  end

  def home= homedir
    raise "homedir must be a directory" unless File.directory? homedir
    @home = homedir
  end
  def home
    @home
  end
end
