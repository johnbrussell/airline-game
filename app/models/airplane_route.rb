class AirplaneRoute < ApplicationRecord
  validates :airline_route_id, presence: true
  validates :airplane_id, presence: true
  validates :block_time_mins, presence: true
  validates :block_time_mins, numericality: { greater_than: 0 }
  validates :flight_cost, presence: true
  validates :flight_cost, numericality: { greater_than: 0 }
  validates :frequencies, presence: true
  validates :frequencies, numericality: { greater_than: 0 }

  validate :routes_connected

  before_destroy :validate_remaining_routes_connected

  belongs_to :airplane
  belongs_to :route, class_name: "AirlineRoute", foreign_key: :airline_route_id

  private

    def routes_connected
      if !airplane.routes_connected_with?(route.origin_airport_iata, route.destination_airport_iata)
        errors.add(:route, "does not connect to airplane's route network")
      end
    end

    def validate_remaining_routes_connected
      if !airplane.routes_connected_without?(route.origin_airport_iata, route.destination_airport_iata)
        errors.add(:route, "is necessary to keep airplane's routes connected")
        throw :abort
      end
    end
end
