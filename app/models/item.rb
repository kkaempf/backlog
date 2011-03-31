require 'active_model'

class Item
  include ActiveModel::Validations
  extend ActiveModel::Naming

  attr_reader :created_by, :created_on, :epic, :persona, :title, :description

  def initialize
  end

  def id
    "item_id"
  end

  def to_s
    "item_s"
  end

  def to_key
    ["0"]
  end
  
  def method_missing name, *args
    Rails.logger.info "Items.#{name.to_s} not implemented"
    nil
  end
end