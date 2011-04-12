require 'lib/git'
require 'lib/backlog_rc'

class DashboardController < ApplicationController
  
  def initialize
    @git = Backlog::Git.instance.git
    @rc = Backlog::BacklogRc.instance
    super
  end

  def login
  end

  def logout
  end

  def index
    @items = Item.find :all
  end

end
