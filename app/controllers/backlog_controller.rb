require 'lib/backlog_template'

class BacklogController < ApplicationController
  def new
    @template = BacklogTemplate.new
  end
  
  #
  # item moved to trash
  #
  def trash
    begin
      id = params["id"]
      uuid = SimpleUUID::UUID.new(id).to_guid
      result = Item.remove uuid
    rescue
      if uuid.nil?
	flash[:error] = "Invalid item >%s<" % id
      elsif result.nil?
	flash[:error] = "No such item: #{uuid}"
      elsif result
	flash[:error] = "Item #{uuid} removed"
      else
	flash[:error] = "Internal error"
      end
    end

    redirect_to "/"
  end
  
  def sort
    epics_list = params["epics_list"]
    @@item_cache.sort epics_list
    redirect_to "/"
  end
end
