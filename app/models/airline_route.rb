class AirlineRoute < ApplicationRecord
  REPUTATION_WEIGHTS = {
    fare: 0.3,
    frequency: 0.3,
    ifs: 0.1,
    legroom: 0.3,
  }
  MIN_REPUTATION = 1
  MAX_REPUTATION = 4
  MIN_SERVICE_QUALITY = 1
  MAX_SERVICE_QUALITY = 5

  validates :economy_price, presence: true
  validates :economy_price, numericality: { greater_than: 0 }
  validates :premium_economy_price, presence: true
  validates :premium_economy_price, numericality: { greater_than: 0 }
  validates :business_price, presence: true
  validates :business_price, numericality: { greater_than: 0 }
  validates :origin_airport_id, presence: true
  validates :destination_airport_id, presence: true
  validates :service_quality, presence: true
  validates :service_quality, numericality: { greater_than_or_equal_to: MIN_SERVICE_QUALITY, less_than_or_equal_to: MAX_SERVICE_QUALITY }
  validate :airline_can_fly_route
  validate :airports_alphabetized

  has_one :revenue, class_name: "AirlineRouteRevenue"
  has_many :airplane_routes
  has_many :airplanes, through: :airplane_routes
  belongs_to :airline
  belongs_to :origin_airport, class_name: "Airport"
  belongs_to :destination_airport, class_name: "Airport"

  delegate :iata, to: :origin_airport, prefix: true
  delegate :iata, to: :destination_airport, prefix: true

  def self.find_or_create_by_airline_and_route(airline, origin_airport, destination_airport)
    record = find_or_create_by(airline: airline, origin_airport: origin_airport, destination_airport: destination_airport)
    if record.new_record?
      route_dollars_in_market = RouteDollars.between_markets(origin_airport.market, destination_airport.market, Game.find(airline.game_id).current_date)
      total_dollars_in_market = route_dollars_in_market.sum { |rd| rd.business + rd.economy + rd.premium_economy }
      distance = if total_dollars_in_market > 0 then route_dollars_in_market.sum { |rd| (rd.business.to_f / total_dollars_in_market + rd.economy.to_f / total_dollars_in_market + rd.premium_economy.to_f / total_dollars_in_market) * rd.distance } else 0 end
      inertia = Calculation::InertiaRouteService.new(distance, route_dollars_in_market.sum(&:business), route_dollars_in_market.sum(&:economy), route_dollars_in_market.sum(&:premium_economy))
      record.assign_attributes(
        economy_price: (inertia.economy_fare > 0 ? inertia.economy_fare : record.distance).round(2),
        premium_economy_price: (inertia.premium_economy_fare > 0 ? inertia.premium_economy_fare : record.distance * 2).round(2),
        business_price: (inertia.business_fare > 0 ? inertia.business_fare : record.distance * 3).round(2),
      )
      record.save
    end
    record
  end

  def self.operators_in_market(origin_market, destination_market, game)
    AirlineRoute
      .joins(:airplane_routes)
      .joins(:airline)
      .joins("INNER JOIN airports AS origin_airports ON airline_routes.origin_airport_id == origin_airports.id")
      .joins("INNER JOIN airports AS destination_airports ON airline_routes.destination_airport_id == destination_airports.id")
      .where("(origin_airports.market_id == #{origin_market.id} AND destination_airports.market_id == #{destination_market.id})
              OR (destination_airports.market_id == #{origin_market.id} AND origin_airports.market_id == #{destination_market.id})")
      .where("airlines.game_id == ?", game.id)
      .order("airlines.name")
      .uniq
  end

  def self.operators_of_other_market_routes(origin, destination, game)
    AirlineRoute
      .joins(:airplane_routes)
      .joins(:airline)
      .joins("INNER JOIN airports AS origin_airports ON airline_routes.origin_airport_id == origin_airports.id")
      .joins("INNER JOIN airports AS destination_airports ON airline_routes.destination_airport_id == destination_airports.id")
      .where("(origin_airports.market_id == #{origin.market_id} AND destination_airports.market_id == #{destination.market_id})
              OR (destination_airports.market_id == #{origin.market_id} AND origin_airports.market_id == #{destination.market_id})")
      .where.not(origin_airport_id: origin.id, destination_airport_id: destination.id)
      .where("airlines.game_id == ?", game.id)
      .order("origin_airports.iata", "destination_airports.iata")
      .uniq
  end

  def self.operators_of_route(origin, destination, game)
    AirlineRoute
      .joins(:airplane_routes)
      .joins(:airline)
      .where(origin_airport_id: origin.id, destination_airport_id: destination.id)
      .where("airlines.game_id == ?", game.id)
      .order("airlines.name")
      .uniq
  end

  def airplanes_available_to_add_service(game)
    Airplane
      .where(operator_id: airline.id)
      .where("airplanes.id NOT IN (?)", airplanes.map(&:id) + ["default value because empty lists cause where not in commands to always return []"])
      .built(game)
      .neatly_sorted
      .select { |a| a.can_fly_between?(origin_airport, destination_airport) }
      .select { |a| a.has_time_to_fly?(distance) }
  end

  def distance
    @distance ||= Calculation::Distance.between_airports(origin_airport, destination_airport)
  end

  def flight_profit
    # Revenue and flight costs are both round trip
    (revenue.revenue - total_flight_costs) / 7.0
  end

  def frequencies_on_airplane(airplane)
    airplane_routes.select { |ar| ar.airplane == airplane }.sum(&:frequencies)
  end

  def load_factor
    (revenue.economy_pax + revenue.premium_economy_pax + revenue.business_pax) / total_seats.to_f * 100
  end

  def name
    "#{origin_airport_iata} - #{destination_airport_iata}"
  end

  def reputation
    @reputation ||= REPUTATION_WEIGHTS[:fare] * fare_reputation + REPUTATION_WEIGHTS[:frequency] * frequency_reputation + REPUTATION_WEIGHTS[:ifs] * ifs_reputation + REPUTATION_WEIGHTS[:legroom] * legroom_reputation
  end

  def set_price(economy, premium_economy, business)
    update(economy_price: economy, premium_economy_price: premium_economy, business_price: business) && update_revenue
  end

  def set_service_quality(new_quality)
    update(service_quality: new_quality) && airplane_routes.each(&:update_costs) && update_revenue
  end

  def total_flight_costs
    airplane_routes.sum { |ar| ar.frequencies * ar.flight_cost }
  end

  def total_frequencies
    airplane_routes.sum(&:frequencies)
  end

  def total_business_seats
    airplane_routes.sum do |airplane_route|
      airplane_route.frequencies * airplane_route.airplane.business_seats
    end
  end

  def total_economy_seats
    airplane_routes.sum do |airplane_route|
      airplane_route.frequencies * airplane_route.airplane.economy_seats
    end
  end

  def total_premium_economy_seats
    airplane_routes.sum do |airplane_route|
      airplane_route.frequencies * airplane_route.airplane.premium_economy_seats
    end
  end

  def total_seats
    airplane_routes.sum { |ar| ar.frequencies * ar.airplane.num_seats }
  end

  def update_revenue
    if total_frequencies == 0
      revenue&.zero_out
    end
    MarketRevenue::Updater.new(origin_airport.market, destination_airport.market, game).update
  end

  private

    def airline_can_fly_route
      if !airline.can_fly_between?(origin_airport.market, destination_airport.market)
        errors.add(:airline, "cannot fly between these airports due to political restrictions")
      end
    end

    def airports_alphabetized
      if Airport.find(destination_airport_id).iata <= Airport.find(origin_airport_id).iata
        errors.add(:destination_airport_id, "must correspond to an airport with iata alphabetically after origin airport's iata")
      end
    end

    def business_fare_reputation
      1 - (business_price / max_route_business_fare.to_f)
    end

    def calculate_inertia_route
      route_dollars_in_market = RouteDollars.between_markets(origin_airport.market, destination_airport.market, game.current_date)
      total_dollars_in_market = route_dollars_in_market.sum { |rd| rd.business + rd.economy + rd.premium_economy }
      inertia_distance = route_dollars_in_market.sum { |rd| (rd.business.to_f / total_dollars_in_market + rd.economy.to_f / total_dollars_in_market + rd.premium_economy.to_f / total_dollars_in_market) * rd.distance }
      @inertia_route ||= Calculation::InertiaRouteService.new(inertia_distance, route_dollars_in_market.sum(&:business), route_dollars_in_market.sum(&:economy), route_dollars_in_market.sum(&:premium_economy))
    end

    def economy_fare_reputation
      1 - (economy_price / max_route_economy_fare.to_f)
    end

    def game
      @game ||= Game.find(airline.game_id)
    end

    def fare_reputation
      scale_reputation((business_fare_reputation * total_business_seats + economy_fare_reputation * total_economy_seats + premium_economy_fare_reputation * total_premium_economy_seats) / total_seats.to_f, 0, 1)
    end

    def frequency_reputation
      scale_reputation([total_frequencies, 245].min, 1, 245)
    end

    def ifs_reputation
      scale_reputation(service_quality, 1, 5)
    end

    def inertia_route
      @inertia_route ||= calculate_inertia_route
    end

    def legroom_reputation
      avg_reputation = airplane_routes.sum { |ar| ar.frequencies * ar.airplane.num_seats * ar.airplane.legroom_reputation } / total_seats.to_f
      scale_reputation(avg_reputation, 0, 1)
    end

    def max_route_business_fare
      [AirlineRoute.operators_of_route(origin_airport, destination_airport, game).map(&:business_price).max, inertia_route.business_fare, 1].compact.max
    end

    def max_route_economy_fare
      [AirlineRoute.operators_of_route(origin_airport, destination_airport, game).map(&:economy_price).max, inertia_route.economy_fare].compact.max
    end

    def max_route_premium_economy_fare
      [AirlineRoute.operators_of_route(origin_airport, destination_airport, game).map(&:premium_economy_price).max, inertia_route.premium_economy_fare].compact.max
    end

    def premium_economy_fare_reputation
      1 - (premium_economy_price / max_route_premium_economy_fare.to_f)
    end

    def scale_reputation(input_reptuation, input_min, input_max)
      (input_reptuation - input_min) * (MAX_REPUTATION - MIN_REPUTATION) / (input_max - input_min).to_f + MIN_REPUTATION
    end
end
