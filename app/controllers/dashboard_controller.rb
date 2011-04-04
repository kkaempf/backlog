require 'lib/git'

class DashboardController < ApplicationController
  
  def initialize
    @git = Backlog::Git.instance.git
    @rc = BacklogRc.instance
    super
  end

  def login
  end

  def logout
  end

  def index
  end

end
