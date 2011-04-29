require 'git'
require 'singleton'
require 'lib/backlog_rc'

module Backlog
  class Git
    include Singleton
    attr_reader :git
    def initialize
      rc = BacklogRc.instance
      begin
	File.mkdir(rc.home) unless File.directory?(rc.home)
	@git = ::Git.open(rc.home, :log => Rails.logger)
      rescue ArgumentError => e
	Rails.logger.warn e.inspect
	@git = ::Git.init rc.home
	gitignore = File.join(rc.home, ".gitignore")
	File.open(gitignore, "w") do |f|
	  f.write <<-GITIGNORE
*~
*.bak
	  GITIGNORE
	end
	@git.add gitignore
	@git.commit "Initial .gitignore"
      end
      unless @git.config('user.name')
	raise "'name' must be set in @rc.path"
      end
      unless @git.config('user.email')
	raise "'email' must be set in @rc.path"
      end
      if rc.origin
	Dir.chdir do |dir|
	  system "git remote add origin #{rc.origin}"
	end
      else
	Rails.logger.warn "'origin' not set in backlogrc"
      end
    end

  end # class
  
end # module
