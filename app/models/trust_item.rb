class TrustItem < ApplicationRecord
  validates_uniqueness_of :url, message: "This item is already in your system!"

  def self.search(search_value)
    if search_value.present?
      where("title LIKE ?", "%#{search_value}%")
    else
      all
    end
  end
end