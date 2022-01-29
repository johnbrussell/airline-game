class AirplaneRoute < ApplicationRecord
  validates :airline_route_id, presence: true
  validates :airplane_id, presence: true
  validates :block_time_mins, presence: true
  validates :block_time_mins, numericality: { greater_than_or_equal_to: 0 }
  validates :flight_cost, presence: true
  validates :flight_cost, numericality: { greater_than_or_equal_to: 0 }
  validates :frequencies, presence: true
  validates :frequencies, numericality: { greater_than_or_equal_to: 0 }
end
