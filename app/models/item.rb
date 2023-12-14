class Item < ApplicationRecord
  validates_uniqueness_of :url, message: "This item is already in your system!"
end
