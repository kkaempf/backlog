class ApplicationController < ActionController::Base
  protect_from_forgery
  @@item_cache = ItemCache.instance
  @@item_cache.fill_cache
end
