#
# Items is a Resource
#
class ItemsController < ApplicationController
  def update
    @item = Item.find(params["id"]) || Item.new
    Rails.logger.info "ItemsController.update #{params.inspect}"
    params["item"].each do |key,value|
      @item.send "#{key}=", value
    end
    @item.save    
    redirect_to "/"
  end
end
