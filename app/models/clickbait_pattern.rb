class ClickbaitPattern < ApplicationRecord
  validates_uniqueness_of :pattern
end
