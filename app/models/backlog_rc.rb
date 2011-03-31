require 'active_model'
require 'yaml'
require 'singleton'

BACKLOGRC_PATH = "~/.backlogrc"
class BacklogRc
  include Singleton
  include ActiveModel::Validations
  extend ActiveModel::Naming

  validates :home, :presence => true
  attr_reader :home

  def initialize
    begin
      File.open(File.expand_path(BACKLOGRC_PATH)) do |f|
	rc = YAML.load(f)
	@home = rc["home"]
      end
    rescue
      Rails.logger.warn "~/.backlogrc not readable"
    end
    @home = File.expand_path(@home || "~")
  end

  def home= homedir
    raise "homedir must be a directory" unless File.directory? homedir
    @home = homedir
  end

end
