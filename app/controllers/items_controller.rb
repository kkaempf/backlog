#
# Items is a Resource
#

class ItemsController < ApplicationController
private
  def update_item item, params
    params["item"].each do |key,value|
      item.send "#{key}=", value
    end
    result = item.save # will validate
    if result == false
      item.errors.each do |attr, errors|
	errors.each do |err|
	  flash[:error] = "#{attr}: #{err}"
	end
      end
    end	
    redirect_to "/"
  end
public

  def new
    require 'lib/backlog_template'
    @template = BacklogTemplate.new
  end
  
  def create
    item = Item.new
    update_item item, params
    unless item.valid?
      @@item_cache.remove item
    end
    return
  end

  def update
    update_item Item.find(params["id"]), params
    return
  end
  
  def show
    begin
      id = params["id"]
      uuid = SimpleUUID::UUID.new(id).to_guid
      @item = Item.find :id => uuid
      raise unless @item
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
  #
  # item moved to trash
  #
  def destroy
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
  
end
