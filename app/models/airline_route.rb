class AirlineRoute < ApplicationRecord
  validates :economy_price, presence: true
  validates :economy_price, numericality: { greater_than: 0 }
  validates :premium_economy_price, presence: true
  validates :premium_economy_price, numericality: { greater_than: 0 }
  validates :business_price, presence: true
  validates :business_price, numericality: { greater_than: 0 }
  validates :origin_airport_id, presence: true
  validates :destination_airport_id, presence: true

  has_many :airplane_routes
  has_many :airplanes, through: :airplane_routes
end
