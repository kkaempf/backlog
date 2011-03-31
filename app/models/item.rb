require 'active_model'

class Item
  include ActiveModel::Validations
  extend ActiveModel::Naming

  attr_reader :created_by, :created_on, :epic, :persona, :title, :description

  def initialize
  end

  def to_key
    ["0"]
  end
end