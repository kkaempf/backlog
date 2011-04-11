
class BacklogController < ApplicationController
  def sort
    epics_list = params["epics_list"]
    @@item_cache.sort epics_list
    redirect_to "/"
  end
end
