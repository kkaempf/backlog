require 'git'
require 'singleton'

module Backlog
  class Git
    include Singleton
    attr_reader :git
    def initialize
      rc = BacklogRc.instance
      begin
	@git = ::Git.open(rc.home, :log => Rails.logger)
      rescue ArgumentError => e
	Rails.logger.warn e.inspect
	@git = ::Git.init rc.home
      end
      unless @git.config('user.name')
	raise "'name' must be set in @rc.path"
      end
      unless @git.config('user.email')
	raise "'email' must be set in @rc.path"
      end
    end
  end
end
