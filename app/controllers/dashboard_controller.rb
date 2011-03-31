class DashboardController < ApplicationController
  
  def login
  end

  def logout
  end

  def index
    @rc = BacklogRc.instance
  end

end
