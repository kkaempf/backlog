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
    item = Item.new params[:subject]
    update_item(item, params) and return
  end

  def update
    update_item(Item.find(params["id"]), params) and return
  end
  
  def show
    begin
      id = params["id"]
      @item = Item.find :id => id
      raise unless @item
    rescue
      if id.nil?
	flash[:error] = "Invalid item >%s<" % id
      elsif @item.nil?
	flash[:error] = "Item #{id} not found"
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
      result = Item.remove id
    rescue
      if id.nil?
	flash[:error] = "Invalid item >%s<" % id
      elsif result.nil?
	flash[:error] = "No such item: #{id}"
      elsif result
	flash[:error] = "Item #{id} removed"
      else
	flash[:error] = "Internal error"
      end
    end

    redirect_to "/"
  end
  
end
