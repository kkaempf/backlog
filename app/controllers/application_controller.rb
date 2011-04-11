class ApplicationController < ActionController::Base
  protect_from_forgery
  @@item_cache = ItemCache.instance
end
