class AirlineRouteRevenue < ApplicationRecord
  validates :airline_route_id, presence: true
  validates :economy_pax, presence: true
  validates :economy_pax, numericality: { greater_than_or_equal_to: 0 }
  validates :premium_economy_pax, presence: true
  validates :premium_economy_pax, numericality: { greater_than_or_equal_to: 0 }
  validates :business_pax, presence: true
  validates :business_pax, numericality: { greater_than_or_equal_to: 0 }
  validates :revenue, presence: true
  validates :revenue, numericality: { greater_than_or_equal_to: 0 }
end
