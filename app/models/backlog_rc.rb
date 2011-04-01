require 'active_model'
require 'yaml'
require 'singleton'

BACKLOGRC_PATH = "~/.backlogrc"
class BacklogRc
  include Singleton
  include ActiveModel::Validations
  extend ActiveModel::Naming

  validates :home, :presence => true

  def initialize
    begin
      File.open(File.expand_path(BACKLOGRC_PATH)) do |f|
	rc = YAML.load(f)
	self.home = rc["home"]
	self.name = rc["name"]
	self.email = rc["email"]
      end
    rescue
      Rails.logger.warn "~/.backlogrc not readable"
    end
    self.home = File.expand_path(@home || "~")
  end

  def home= homedir
    raise "homedir must be a directory" unless File.directory? homedir
    @home = homedir
  end
  def home
    @home
  end
end
