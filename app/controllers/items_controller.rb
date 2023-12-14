class ItemsController < ApplicationController
  def index
    @items = Item.all
    @trust_items = TrustItem.all
  end
end