class IslandException < ApplicationRecord
  validates :market_one, presence: true
  validates :market_two, presence: true
end
