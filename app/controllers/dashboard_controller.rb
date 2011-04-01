class DashboardController < ApplicationController
  
  def initialize
    @rc = BacklogRc.instance
    begin
      @git = Git.open(@rc.home, :log => Rails.logger)
    rescue ArgumentError => e
      Rails.logger.warn e.inspect
      @git = Git.init @rc.home
    end
    unless @git.config('user.name')
      raise "'name' must be set in @rc.path"
    end
    unless @git.config('user.email')
      raise "'email' must be set in @rc.path"
    end
    super
  end

  def login
  end

  def logout
  end

  def index
  end

end
