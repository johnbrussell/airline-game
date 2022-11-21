class AirplaneRoute < ApplicationRecord
  validates :airline_route_id, presence: true
  validates :airplane_id, presence: true
  validates :block_time_mins, presence: true
  validates :block_time_mins, numericality: { greater_than: 0 }
  validates :flight_cost, presence: true
  validates :flight_cost, numericality: { greater_than: 0 }
  validates :frequencies, presence: true
  validates :frequencies, numericality: { greater_than: 0 }

  validate :airplane_built
  validate :airplane_can_fly_route
  validate :airplane_operated_by_airline
  validate :airplane_time_is_logical
  validate :airplane_time_is_possible
  validate :routes_connected
  validate :slots_sufficient

  after_save :reload_airplane

  before_destroy :validate_remaining_routes_connected

  belongs_to :airplane
  belongs_to :route, class_name: "AirlineRoute", foreign_key: :airline_route_id

  delegate :legroom_reputation,
           to: :airplane

  delegate :airline,
           :business_price,
           :distance,
           :economy_price,
           :name,
           :premium_economy_price,
           :service_quality,
           to: :route

  DAYS_PER_WEEK = 7.0

  def self.on_route(origin, destination, game)
    AirplaneRoute
      .joins(route: :airline)
      .where("airline_routes.origin_airport_id == ?", origin.id)
      .where("airline_routes.destination_airport_id == ?", destination.id)
      .where("airlines.game_id == ?", game.id)
  end

  def business_reputation_data
    Calculation::ReputationData.new(airline, business_price, frequencies, service_quality, legroom_reputation)
  end

  def daily_profit
    (revenue - expenses) / DAYS_PER_WEEK
  end

  def economy_reputation_data
    Calculation::ReputationData.new(airline, economy_price, frequencies, service_quality, legroom_reputation)
  end

  def premium_economy_reputation_data
    Calculation::ReputationData.new(airline, premium_economy_price, frequencies, service_quality, legroom_reputation)
  end

  def recalculate_profits_and_block_time
    update!(
      block_time_mins: (airplane.round_trip_block_time(route.distance) * frequencies).round,
      flight_cost: one_way_single_frequency_flight_cost * 2,
    ) && route.update_revenue && true
  end

  def set_frequency(frequency)
    if frequency > 0
      assign_attributes(
        block_time_mins: (airplane.round_trip_block_time(route.distance) * frequency).round,
        flight_cost: one_way_single_frequency_flight_cost * 2,
        frequencies: frequency,
      )
      save
    else
      destroy!
    end && route.update_revenue
  end

  def update_costs
    update(flight_cost: one_way_single_frequency_flight_cost * 2)
  end

  private

    def airplane_built
      if !airplane.built?
        errors.add(:airplane, "cannot fly before it is built")
      end
    end

    def airplane_can_fly_route
      if !airplane.can_fly_between?(route.origin_airport, route.destination_airport)
        errors.add(:airplane, "cannot fly this route")
      end
    end

    def airplane_operated_by_airline
      if airplane.operator_id != route.airline.id
        errors.add(:operator, "of airplane does not match airline_route")
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

    def expenses
      frequencies * flight_cost
    end

    def one_way_single_frequency_flight_cost
      Calculation::FlightCostCalculator.new(airplane, distance, service_quality).cost
    end

    def other_airplane_routes
      airplane.airplane_routes.reject { |r| r.id == id }
    end

    def revenue
      revenue_business + revenue_economy + revenue_premium_economy
    end

    def revenue_business
      if route.total_business_seats > 0
        airplane.business_seats * frequencies / route.total_business_seats.to_f * route.business_price * route.revenue.business_pax * 2
      else
        0
      end
    end

    def revenue_economy
      if route.total_economy_seats > 0
        airplane.economy_seats * frequencies / route.total_economy_seats.to_f * route.economy_price * route.revenue.economy_pax * 2
      else
        0
      end
    end

    def revenue_premium_economy
      if route.total_premium_economy_seats > 0
        airplane.premium_economy_seats * frequencies / route.total_premium_economy_seats.to_f * route.premium_economy_price * route.revenue.premium_economy_pax * 2
      else
        0
      end
    end

    def routes_connected
      if !airplane.routes_connected_with?(route.origin_airport_iata, route.destination_airport_iata)
        errors.add(:route, "does not connect to airplane's route network")
      end
    end

    def slots_leased_at(airport)
      Slot.num_leased(route.airline, airport)
    end

    def slots_leased_at_destination
      slots_leased_at(route.destination_airport)
    end

    def slots_leased_at_origin
      slots_leased_at(route.origin_airport)
    end

    def slots_sufficient
      if slots_used_at_origin + frequencies > slots_leased_at_origin || slots_used_at_destination + frequencies > slots_leased_at_destination
        errors.add(:slots, "not leased in sufficient quantity")
      end
    end

    def slots_used_at(airport)
      frequencies = new_record? ? 0 : AirplaneRoute.find(id).frequencies

      Slot.num_used(route.airline, airport) - frequencies
    end

    def slots_used_at_destination
      slots_used_at(route.destination_airport)
    end

    def slots_used_at_origin
      slots_used_at(route.origin_airport)
    end

    def validate_remaining_routes_connected
      if !airplane.routes_connected_without?(route.origin_airport_iata, route.destination_airport_iata)
        errors.add(:route, "is necessary to keep airplane's routes connected")
        throw :abort
      end
    end
end
