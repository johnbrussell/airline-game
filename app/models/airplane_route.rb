class AirplaneRoute < ApplicationRecord
  validates :airline_route_id, presence: true
  validates :airplane_id, presence: true
  validates :block_time_mins, presence: true
  validates :block_time_mins, numericality: { greater_than: 0 }
  validates :flight_cost, presence: true
  validates :flight_cost, numericality: { greater_than: 0 }
  validates :frequencies, presence: true
  validates :frequencies, numericality: { greater_than: 0 }

  validate :airplane_can_fly_route
  validate :airplane_time_is_logical
  validate :airplane_time_is_possible
  validate :routes_connected

  before_destroy :validate_remaining_routes_connected

  belongs_to :airplane
  belongs_to :route, class_name: "AirlineRoute", foreign_key: :airline_route_id

  private

    def airplane_can_fly_route
      if !airplane.can_fly_between?(route.origin_airport, route.destination_airport)
        errors.add(:airplane, "cannot fly this route")
      end
    end

    def airplane_time_is_logical
      if (airplane.round_trip_block_time(route.distance) * frequencies).round != block_time_mins
        errors.add(:block_time_mins, "is not correct")
      end
    end

    def airplane_time_is_possible
      if other_airplane_routes.map(&:block_time_mins).sum + block_time_mins > Airplane::MAX_TOTAL_BLOCK_TIME_MINS
        errors.add(:airplane, "has too much block time")
      end
    end

    def other_airplane_routes
      airplane.airplane_routes.reject { |r| r.id == id }
    end

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
