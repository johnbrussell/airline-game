class IslandException < ApplicationRecord
  validates :market_one, presence: true
  validates :market_two, presence: true

  def self.excepted?(market_1, market_2)
    find_by(market_one: market_1.name, market_two: market_2.name).present? ||
      find_by(market_one: market_2.name, market_two: market_1.name).present?
  end
end
