class Airplane < ApplicationRecord
  validates :base_country_group, presence: true
  validates :business_seats, presence: true
  validates :business_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :construction_date, presence: true
  validates :economy_seats, presence: true
  validates :economy_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :end_of_useful_life, presence: true
  validates :premium_economy_seats, presence: true
  validates :premium_economy_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :lease_rate, numericality: { greater_than: 0 }, allow_nil: true

  validate :base_changes_appropriately, unless: :new_record?
  validate :based_in_right_country
  validate :block_time_feasible
  validate :can_fly_routes
  validate :operator_changes_appropriately, unless: :new_record?
  validate :seats_fit_on_plane

  before_save :update_downstream_block_times

  belongs_to :aircraft_manufacturing_queue
  belongs_to :aircraft_model

  has_many :airplane_routes
  has_many :routes, class_name: "AirlineRoute", through: :airplane_routes

  delegate :game, :to => :aircraft_manufacturing_queue
  delegate :max_economy_seats, :to => :aircraft_model

  scope :available_new, ->(game) {
    joins(:aircraft_manufacturing_queue).
    where(operator_id: nil).
    where("construction_date > ?", game.current_date).
    where(aircraft_manufacturing_queue: { game: game } )
  }
  scope :available_used, ->(game) {
    joins(:aircraft_manufacturing_queue).
    where(operator_id: nil).
    where("construction_date <= ?", game.current_date).where("end_of_useful_life > ?", game.current_date).
    where(aircraft_manufacturing_queue: { game: game } )
  }
  scope :neatly_sorted, -> {
    joins(aircraft_model: :family).
    order("aircraft_families.manufacturer", "aircraft_families.name", "aircraft_models.name", "construction_date DESC")
  }
  scope :with_operator, ->(operator_id) { where(operator_id: operator_id) }

  ECONOMY_SEAT_SIZE = 28 * 17
  PREMIUM_ECONOMY_SEAT_SIZE = 36 * 17
  BUSINESS_SEAT_SIZE = 72 * 17
  ELEVATION_FOR_TAKEOFF_MULTIPLIER = 2000
  EMPTY_PLANE_RANGE_MULTIPLIER = 1.25
  MIN_MAINTENANCE_RATE = 0.8
  MAX_LEASE_DAYS = 3652
  MAX_TOTAL_BLOCK_TIME_MINS = 20 * 7 * 60
  MIN_PERCENT_OF_LEASE_NEEDED_AS_CASH_ON_HAND_TO_LEASE = 0.08
  MIN_TURN_TIME_MINS = 10
  NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE = 100.0
  PERCENT_OF_USEFUL_LIFE_LEASED_FOR_FULL_VALUE = 0.4
  TAKEOFF_ELEVATION_MULTIPLIER = 1.15
  TURN_TIME_MINS_PER_SEAT = 1/3.5

  def block_time(distance)
    # Note this is for one way!  Need two block times for a plane to operate one frequency on a route
    aircraft_model.flight_time_mins(distance) + turn_time_mins
  end

  def built?
    construction_date <= aircraft_manufacturing_queue.game.current_date
  end

  def can_fly_between?(airport_1, airport_2)
    distance = Calculation::Distance.between_airports(airport_1, airport_2)

    distance <= range_from_airport(airport_1) &&
      distance <= range_from_airport(airport_2) &&
      takeoff_distance(airport_1.elevation, distance) <= airport_1.runway &&
      takeoff_distance(airport_2.elevation, distance) <= airport_2.runway &&
      routes_connected_with?(airport_1.iata, airport_2.iata)
  end

  def has_operator?
    operator_id.present?
  end

  def lease(airline, length_in_days, business_seats, premium_economy_seats, economy_seats)
    lease_start_date = built? ? aircraft_manufacturing_queue.game.current_date : construction_date
    if built?
      assign_attributes(base_country_group: airline.base.country_group, lease_rate: lease_rate_per_day(length_in_days.to_i), lease_expiry: lease_start_date + length_in_days.to_i.days)
      airline.assign_attributes(cash_on_hand: airline.cash_on_hand - lease_rate_per_day(length_in_days.to_i))
    else
      assign_attributes(
        base_country_group: airline.base.country_group,
        business_seats: business_seats,
        premium_economy_seats: premium_economy_seats,
        economy_seats: economy_seats,
        lease_expiry: lease_start_date + length_in_days.to_i.days,
        lease_rate: lease_rate_per_day(length_in_days.to_i),
      )
    end

    validate
    airline.validate

    airline.errors.each do |error|
      errors.add("airline_#{error.attribute.to_sym}", error.message)
    end
    if operator_id.present?
      errors.add(:operator_id, "cannot be present before leasing an airplane")
    else
      assign_attributes(operator_id: airline.id)
    end
    if airline.cash_on_hand < lease_rate_per_day(length_in_days * MIN_PERCENT_OF_LEASE_NEEDED_AS_CASH_ON_HAND_TO_LEASE)
      errors.add(:buyer, "does not have enough cash on hand to lease")
    end

    errors.none? &&
      airline.errors.none? &&
      save &&
      airline.save
  end

  def lease_rate_per_day(lease_in_days)
    (value - value_at_age(age_in_days + lease_in_days)) * lease_premium / lease_in_days
  end

  def maintenance_cost_per_day
    aircraft_model.maintenance_cost_per_day(age_in_days) * maintenance_rate
  end

  def new_plane_payment
    value / 2.0
  end

  def purchase(airline, business_seats, premium_economy_seats, economy_seats)
    if built?
      assign_attributes(base_country_group: airline.base.country_group)
    else
      assign_attributes(
        base_country_group: airline.base.country_group,
        business_seats: business_seats,
        premium_economy_seats: premium_economy_seats,
        economy_seats: economy_seats,
      )
    end
    validate

    if operator_id.present?
      errors.add(:operator_id, "cannot be present before buying an airplane")
    end
    if airline.cash_on_hand < purchase_payment
      errors.add(:buyer, "does not have enough cash on hand to purchase")
    end

    errors.none? &&
      save &&
      update(operator_id: airline.id) &&
      airline.update!(cash_on_hand: airline.cash_on_hand - purchase_payment)
  end

  def purchase_price
    value
  end

  def range_from_airport(airport)
    [range_with_unlimited_runway, range_with_runway_and_elevation(airport.runway, airport.elevation)].min
  end

  def round_trip_block_time(distance)
    2 * block_time(distance)
  end

  def routes_connected_with?(origin_iata, destination_iata)
    origin_destination_pairs_connected?(routes.map{ |r| [r.origin_airport.iata, r.destination_airport.iata] }.append([origin_iata, destination_iata]))
  end

  def routes_connected_without?(origin_iata, destination_iata)
    origin_destination_pairs_connected?(routes.map { |r| [r.origin_airport.iata, r.destination_airport.iata] }.reject { |e| e.sort == [origin_iata, destination_iata].sort})
  end

  def takeoff_distance(elevation, flight_distance)
    takeoff_elevation_multiplier(elevation) * 0.5 * aircraft_model.takeoff_distance * takeoff_seats_component * takeoff_flight_distance_component(flight_distance)
  end

  def turn_time_mins
    MIN_TURN_TIME_MINS + num_seats.to_f / (aircraft_model.num_aisles ** 0.5) * TURN_TIME_MINS_PER_SEAT
  end

  private

    def age_in_days
      [(game.current_date - construction_date).to_i, 0].max
    end

    def airline_to_airline_transfer?
      copy = Airplane.find(id)
      copy.operator_id != operator_id && copy.operator_id.present? && operator_id.present?
    end

    def base_changes_appropriately
      copy = Airplane.find(id)
      if RivalCountryGroup.rivals?(copy.base_country_group, base_country_group)
        errors.add(:base_country_group, "cannot be changed between rival countries")
      end
    end

    def based_in_right_country
      if operator_id.present? && Airline.find(operator_id).base.country_group != base_country_group
        errors.add(:base_country_group, "different from operator's base")
      end
    end

    def block_time_feasible
      if total_block_time > MAX_TOTAL_BLOCK_TIME_MINS
        errors.add(:airplane_routes, "block time is too high")
      end
    end

    def can_fly_routes
      if !routes.all?{ |r| can_fly_between?(r.origin_airport, r.destination_airport) }
        errors.add(:routes, "are not all able to be flown by the aircraft")
      end
    end

    def is_transfer_while_utilized?
      copy = Airplane.find(id)
      copy.operator_id != operator_id && airplane_routes.any?
    end

    def lease_premium
      model.price / (model.price - value_at_age(PERCENT_OF_USEFUL_LIFE_LEASED_FOR_FULL_VALUE * model.useful_life * AircraftModel::DAYS_PER_YEAR))
    end

    def maintenance_rate
      [MIN_MAINTENANCE_RATE, MIN_MAINTENANCE_RATE + (1 - MIN_MAINTENANCE_RATE) * ((NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE - 1) - (num_in_family - 1)) / (NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE - 1)].max
    end

    def model
      @model ||= AircraftModel.find_by(id: aircraft_model_id)
    end

    def num_in_family
      Airplane.
        joins(aircraft_model: :family).
        where(operator_id: operator_id).
        where("construction_date <= ?", game.current_date).
        where("aircraft_families.id == ?", aircraft_model.family.id).
        count
    end

    def num_seats
      economy_seats + premium_economy_seats + business_seats
    end

    def operator_changes_appropriately
      if is_transfer_while_utilized?
        errors.add(:operator_id, "cannot be changed while airplane is utilized")
      elsif airline_to_airline_transfer?
        errors.add(:operator_id, "cannot be changed from one airline directly to another; must be put on the market first")
      end
    end

    def percent_of_max_seats_uninstalled
      (max_economy_seats - num_seats) / max_economy_seats.to_f
    end

    def present_od_pairs_connected?(od_pairs)
      seen_airports = Set.new(od_pairs.fetch(0))
      new_airports = Set.new(od_pairs.fetch(0))
      while new_airports.present?
        new_airports = Set.new(od_pairs.select{ |o, d| seen_airports.include?(o) || seen_airports.include?(d) }.flatten)
        new_airports = new_airports - seen_airports
        seen_airports = new_airports | seen_airports
      end
      od_pairs.all?{ |o, d| seen_airports.include?(o) && seen_airports.include?(d) }
    end

    def purchase_payment
      built? ? purchase_price : new_plane_payment
    end

    def origin_destination_pairs_connected?(od_pairs)
      od_pairs.empty? ? true : present_od_pairs_connected?(od_pairs)
    end

    def range_with_runway_and_elevation(runway_length, elevation)
      [0, 2 * aircraft_model.max_range * Math.log(runway_length / seats_elevation_range_constant(elevation), 2)].max
    end

    def range_with_unlimited_runway
      aircraft_model.max_range * (EMPTY_PLANE_RANGE_MULTIPLIER ** percent_of_max_seats_uninstalled)
    end

    def seats_elevation_range_constant(elevation)
      takeoff_elevation_multiplier(elevation) * 0.5 * aircraft_model.takeoff_distance * takeoff_seats_component
    end

    def seats_fit_on_plane
      if ECONOMY_SEAT_SIZE * economy_seats + PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + BUSINESS_SEAT_SIZE * business_seats > aircraft_model.floor_space
        errors.add(:seats, "require more total floor space than available on airplane")
      end
    end

    def takeoff_elevation_multiplier(elevation)
      [1, TAKEOFF_ELEVATION_MULTIPLIER ** (elevation.to_f / ELEVATION_FOR_TAKEOFF_MULTIPLIER)].max
    end

    def takeoff_flight_distance_component(flight_distance)
      2 ** (flight_distance / (2.0 * aircraft_model.max_range))
    end

    def takeoff_seats_component
      2 ** (num_seats / (2.0 * max_economy_seats))
    end

    def total_block_time
      airplane_routes.map{ |r| r.frequencies * round_trip_block_time(r.route.distance) }.sum
    end

    def update_downstream_block_times
      airplane_routes.each do |route|
        route.update(block_time_mins: (route.frequencies * round_trip_block_time(route.route.distance)).round)
      end
    end

    def value
      value_at_age(age_in_days)
    end

    def value_at_age(days)
      model.price * model.daily_value_retention ** days
    end
end
