class BacklogController < ApplicationController
  def new
    @item = Item.new
  end
end
