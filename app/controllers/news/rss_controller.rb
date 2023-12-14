class News::RssController < ApplicationController
  before_action :set_item
  def index

  end


  def set_item
    @item = Item.new
  end
end