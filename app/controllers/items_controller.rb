#
# Items is a Resource
#
class ItemsController < ApplicationController
  def update
    @item = Item.find(params["id"]) || Item.new
    params["item"].each do |key,value|
      @item.send "#{key}=", value
    end
    @item.save    
    redirect_to "/"
  end
  
  def show
    begin
      id = params["id"]
      uuid = SimpleUUID::UUID.new(id).to_guid
      @item = Item.find :id => uuid
    rescue
      if uuid.nil?
	flash[:error] = "Invalid item >%s<" % id
      elsif @item.nil?
	flash[:error] = "Item #{uuid} not found"
      else
	flash[:error] = "Internal error"
      end
      redirect_to("/") and return
    end
  end
end
