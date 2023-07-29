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
  validate :operator_has_rights_to_plane
  validate :seats_fit_on_plane

  before_save :update_downstream_block_times

  belongs_to :aircraft_manufacturing_queue
  belongs_to :aircraft_model

  alias :model :aircraft_model

  delegate :family, to: :aircraft_model

  has_many :airplane_routes
  has_many :routes, class_name: "AirlineRoute", through: :airplane_routes

  delegate :game, :to => :aircraft_manufacturing_queue
  delegate :lease_buyout_premium,
           :lease_premium,
           :max_economy_seats,
           :value_at_age,
           :to => :aircraft_model

  scope :available_new, ->(game) {
    joins(:aircraft_manufacturing_queue).
    where(operator_id: nil).
    where("construction_date > ?", game.current_date).
    where(aircraft_manufacturing_queue: { game: game } )
  }
  scope :available_used, ->(game) {
    joins(:aircraft_manufacturing_queue).
    where(operator_id: nil).
    built(game).
    where("end_of_useful_life > ?", game.current_date).
    where(aircraft_manufacturing_queue: { game: game } )
  }
  scope :built, ->(game) { where("construction_date <= ?", game.current_date) }
  scope :neatly_sorted, -> {
    joins(aircraft_model: :family).
    order("aircraft_families.manufacturer", "aircraft_families.name", "aircraft_models.name", "construction_date DESC")
  }
  scope :with_operator, ->(operator_id) { where(operator_id: operator_id) }

  ECONOMY_SEAT_SIZE = 28 * 17
  PREMIUM_ECONOMY_SEAT_SIZE = 36 * 17
  BUSINESS_SEAT_SIZE = 72 * 17
  BLOCK_TIME_HOURS_PER_DAY_FOR_GOOD_ON_TIME_PERFORMANCE = 5
  DAYS_PER_WEEK = 7.0
  ELEVATION_FOR_TAKEOFF_MULTIPLIER = 2000
  EMPTY_PLANE_RANGE_MULTIPLIER = 1.25
  MIN_MAINTENANCE_RATE = 0.8
  MAX_LEASE_DAYS = 3652
  MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY = 20
  MAX_TOTAL_BLOCK_TIME_MINS = MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY * 7 * 60
  MIN_LEASE_FOR_SALE_LEASEBACK = 365
  MIN_PERCENT_OF_LEASE_NEEDED_AS_CASH_ON_HAND_TO_LEASE = 0.08
  MIN_TURN_TIME_MINS = 10
  MINUTES_PER_HOUR = 60.0
  NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE = 100.0
  PENALTY_LEASE_DAYS = 30
  PENALTY_LEASE_PREMIUM = 1.1
  RECONFIGURATION_COST_PER_SEAT_ECONOMY = 4000
  RECONFIGURATION_COST_PER_SEAT_PREMIUM_ECONOMY = 12500
  RECONFIGURATION_COST_PER_SEAT_BUSINESS = 60000
  RECONFIGURATION_DAYS_PER_SEAT = 1/50.0
  TAKEOFF_ELEVATION_MULTIPLIER = 1.15
  TURN_TIME_MINS_PER_SEAT = 1/3.5

  def block_time(distance)
    # Note this is for one way!  Need two block times for a plane to operate one frequency on a route
    aircraft_model.flight_time_mins(distance) + turn_time_mins
  end

  def built?
    construction_date <= aircraft_manufacturing_queue.game.current_date
  end

  def buy_out_lease
    add_pre_lease_disposition_errors

    buyout_fee = errors.none? ? lease_buyout_fee : nil
    if errors.none? && operator.cash_on_hand < buyout_fee
      errors.add(:operator, "does not have enough cash on hand to buy out lease")
    end

    errors.none? && purchase(operator, nil, nil, nil) && operator.update(cash_on_hand: operator.cash_on_hand - buyout_fee)
  end

  def can_fly_between?(airport_1, airport_2)
    distance = Calculation::Distance.between_airports(airport_1, airport_2)

    distance <= range_from_airport(airport_1) &&
      distance <= range_from_airport(airport_2) &&
      takeoff_distance(airport_1.elevation, distance) <= airport_1.runway &&
      takeoff_distance(airport_2.elevation, distance) <= airport_2.runway &&
      routes_connected_with?(airport_1.iata, airport_2.iata)
  end

  def conclude_lease
    add_pre_lease_disposition_errors
    add_pre_operation_disposition_errors

    if errors.full_messages.exclude?("Lease expiry date must exist to disposition a lease") && errors.full_messages.include?("Routes cannot be flown by an aircraft for it to be removed from the fleet")
      errors.clear
      assign_penalty_lease_extension
    else
      if lease_expiry != game.current_date
        errors.add(:lease_expiry, "cannot be in the future or past to conlude a lease")
      end
      return_to_lessor
    end
  end

  def daily_profit
    airplane_routes.sum(&:daily_profit) - maintenance_cost_per_day - daily_lease_expense
  end

  def has_operator?
    operator_id.present?
  end

  def has_time_to_fly?(distance)
    round_trip_block_time(distance) + total_block_time <= MAX_TOTAL_BLOCK_TIME_MINS
  end

  def lease(airline, length_in_days, business_seats, premium_economy_seats, economy_seats)
    lease_start_date = built? ? aircraft_manufacturing_queue.game.current_date : construction_date
    previous_owner = owner
    if built?
      assign_attributes(base_country_group: airline.base.country_group, lease_rate: lease_rate_per_day(length_in_days.to_i), lease_expiry: lease_start_date + length_in_days.to_i.days, owner_id: nil)
      airline.assign_attributes(cash_on_hand: airline.cash_on_hand - lease_rate_per_day(length_in_days.to_i))
    else
      assign_attributes(
        base_country_group: airline.base.country_group,
        business_seats: business_seats,
        premium_economy_seats: premium_economy_seats,
        economy_seats: economy_seats,
        lease_expiry: lease_start_date + length_in_days.to_i.days,
        lease_rate: lease_rate_per_day(length_in_days.to_i),
        owner_id: nil,
      )
    end

    validate
    airline.validate

    airline.errors.each do |error|
      errors.add("airline_#{error.attribute.to_sym}", error.message)
    end
    if operator_id.present? && operator_id != airline.id
      errors.add(:operator_id, "cannot be present before leasing an airplane")
    else
      assign_attributes(operator_id: airline.id)
    end

    if airline.id == previous_owner&.id
      if airline.cash_on_hand + purchase_price < lease_rate_per_day(length_in_days * MIN_PERCENT_OF_LEASE_NEEDED_AS_CASH_ON_HAND_TO_LEASE)
        errors.add(:buyer, "does not have enough cash on hand to lease")
      end
    elsif airline.cash_on_hand < lease_rate_per_day(length_in_days * MIN_PERCENT_OF_LEASE_NEEDED_AS_CASH_ON_HAND_TO_LEASE)
      errors.add(:buyer, "does not have enough cash on hand to lease")
    end

    errors.none? &&
      airline.errors.none? &&
      save &&
      airline.save &&
      nil_or_true?(previous_owner&.update!(cash_on_hand: previous_owner.cash_on_hand + purchase_payment))
  end

  def lease_rate_per_day(lease_in_days)
    (value - value_at_age(age_in_days + lease_in_days)) * lease_premium / lease_in_days
  end

  def legroom_reputation
    Math.sqrt(1 - floor_space_used.to_f / aircraft_model.floor_space)
  end

  def maintenance_cost_per_day
    aircraft_model.maintenance_cost_per_day(age_in_days) * maintenance_rate
  end

  def new_plane_payment
    value / 2.0
  end

  def num_seats
    economy_seats + premium_economy_seats + business_seats
  end

  def on_time_reputation
    unutilized_block_time = MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY - [
      total_flights,
      utilization,
    ].min
    block_time_divisor = (MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY - BLOCK_TIME_HOURS_PER_DAY_FOR_GOOD_ON_TIME_PERFORMANCE).to_f

    [
      (unutilized_block_time / block_time_divisor) * 0.9 + 0.1,
      1
    ].min
  end

  def purchase(airline, business_seats, premium_economy_seats, economy_seats)
    previous_owner = owner

    assign_attributes(
      base_country_group: airline.base.country_group,
      owner_id: airline.id,
      lease_expiry: nil,
      lease_rate: nil,
    )
    unless built?
      assign_attributes(
        business_seats: business_seats,
        premium_economy_seats: premium_economy_seats,
        economy_seats: economy_seats,
      )
    end

    validate

    if operator_id.present? && operator_id != airline.id
      errors.add(:operator_id, "cannot be present before buying an airplane")
    elsif operator_id == airline.id
      previous_owner = airline
    end
    if airline.cash_on_hand < purchase_payment
      errors.add(:buyer, "does not have enough cash on hand to purchase")
    end

    errors.none? &&
      save &&
      update(operator_id: airline.id) &&
      airline.update!(cash_on_hand: airline.cash_on_hand - purchase_payment) &&
      nil_or_true?(previous_owner&.update!(cash_on_hand: previous_owner.cash_on_hand + purchase_payment))
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

  def scrap
    add_pre_ownership_disposition_errors
    errors.none? &&
      owner.update(cash_on_hand: owner.cash_on_hand + scrap_value) &&
      update(
        end_of_useful_life: game.current_date,
        operator_id: nil,
      )
  end

  def sell
    add_pre_ownership_disposition_errors
    if operator_id.nil?
      errors.add(:operator_id, "cannot be empty when selling an airplane")
    end
    errors.none? && update(operator_id: nil)
  end

  def sell_and_lease_back(length_in_days)
    add_pre_sale_errors

    if length_in_days < MIN_LEASE_FOR_SALE_LEASEBACK
      errors.add(:lease_expiry, "must be at least #{MIN_LEASE_FOR_SALE_LEASEBACK} days to initiate sale and leaseback agreement")
    end

    errors.none? && lease(operator, length_in_days, nil, nil, nil)
  end

  def set_configuration(new_business, new_premium_economy, new_economy)
    if is_same_configuration?(new_economy, new_premium_economy, new_business)
      true
    else
      update_configuration(new_economy, new_premium_economy, new_business)
    end
  end

  def takeoff_distance(elevation, flight_distance)
    takeoff_elevation_multiplier(elevation) * 0.5 * aircraft_model.takeoff_distance * takeoff_seats_component * takeoff_flight_distance_component(flight_distance)
  end

  def terminate_lease
    add_pre_lease_disposition_errors
    add_pre_operation_disposition_errors

    airplane_operator = operator
    termination_fee = lease_termination_fee

    if airplane_operator.cash_on_hand < lease_termination_fee
      errors.add(:operator, "does not have enough cash on hand to pay the lease termination fee")
    end

    errors.none? &&
      update(
        operator_id: nil,
        lease_expiry: nil,
        lease_rate: nil,
      ) &&
      airplane_operator.update(
        cash_on_hand: airplane_operator.cash_on_hand - termination_fee
      )
  end

  def turn_time_mins
    MIN_TURN_TIME_MINS + num_seats.to_f / (aircraft_model.num_aisles ** 0.5) * TURN_TIME_MINS_PER_SEAT
  end

  def utilization
    total_block_time / DAYS_PER_WEEK / MINUTES_PER_HOUR
  end

  private

    def add_pre_lease_disposition_errors
      add_pre_ownership_change_errors

      if owner_id.present?
        errors.add(:owner_id, "cannot terminate a lease for a plane that is owned")
      end

      if lease_expiry.nil?
        errors.add(:lease_expiry, "date must exist to disposition a lease")
      end
    end

    def add_pre_operation_disposition_errors
      if airplane_routes.any?
        errors.add(:routes, "cannot be flown by an aircraft for it to be removed from the fleet")
      end
    end

    def add_pre_ownership_change_errors
      if !built?
        errors.add(:construction_date, "must be in the past in order to remove it from the fleet")
      end
    end

    def add_pre_ownership_disposition_errors
      add_pre_sale_errors
      add_pre_operation_disposition_errors
    end

    def add_pre_sale_errors
      add_pre_ownership_change_errors

      if owner_id.nil?
        errors.add(:owner_id, "cannot be empty when selling or scrapping an airplane")
      end
    end

    def age_in_days
      [(game.current_date - construction_date).to_i, 0].max
    end

    def airline_to_airline_transfer?
      copy = Airplane.find(id)
      copy.operator_id != operator_id && copy.operator_id.present? && operator_id.present?
    end

    def assign_penalty_lease_extension
      lease(operator, PENALTY_LEASE_DAYS, nil, nil, nil) && update(lease_rate: lease_rate * PENALTY_LEASE_PREMIUM)
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

    def cost_to_reconfigure(new_economy, new_premium_economy, new_business)
      if built?
        days_to_reconfigure(new_economy + new_premium_economy + new_business) * daily_profit +
          new_economy * RECONFIGURATION_COST_PER_SEAT_ECONOMY +
          new_premium_economy * RECONFIGURATION_COST_PER_SEAT_PREMIUM_ECONOMY +
          new_business * RECONFIGURATION_COST_PER_SEAT_BUSINESS
      else
        0
      end
    end

    def daily_lease_expense
      lease_rate.nil? ? 0 : lease_rate
    end

    def days_left_on_lease
      (lease_expiry - game.current_date).to_i
    end

    def days_to_reconfigure(new_total_seats)
      (RECONFIGURATION_DAYS_PER_SEAT * new_total_seats).ceil()
    end

    def floor_space_used
      ECONOMY_SEAT_SIZE * economy_seats + PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + BUSINESS_SEAT_SIZE * business_seats
    end

    def is_same_configuration?(economy, premium_economy, business)
      economy == economy_seats && premium_economy == premium_economy_seats && business == business_seats
    end

    def is_transfer_while_utilized?
      copy = Airplane.find(id)
      copy.operator_id != operator_id && airplane_routes.any?
    end

    def lease_buyout_fee
      (value_component_left_on_lease + value_at_age((lease_expiry - construction_date).to_i)) * lease_buyout_premium
    end

    def lease_termination_fee
      value_component_left_on_lease
    end

    def maintenance_rate
      [MIN_MAINTENANCE_RATE, MIN_MAINTENANCE_RATE + (1 - MIN_MAINTENANCE_RATE) * ((NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE - 1) - (num_in_family - 1)) / (NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE - 1)].max
    end

    def nil_or_true?(input)
      input.nil? || input
    end

    def num_in_family
      Airplane.
        joins(aircraft_model: :family).
        where(operator_id: operator_id).
        where("construction_date <= ?", game.current_date).
        where("aircraft_families.id == ?", aircraft_model.family.id).
        count
    end

    def operator
      Airline.find_by(id: operator_id)
    end

    def operator_changes_appropriately
      if is_transfer_while_utilized?
        errors.add(:operator_id, "cannot be changed while airplane is utilized")
      elsif airline_to_airline_transfer?
        errors.add(:operator_id, "cannot be changed from one airline directly to another; must be put on the market first")
      end
    end

    def operator_has_rights_to_plane
      if owner.present? && operator.present? && owner != operator
        errors.add(:operator_id, "cannot be different from owner_id when airplane is owned by an airline")
      end
    end

    def owner
      Airline.find_by(id: owner_id)
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

    def return_to_lessor
      errors.none? &&
        update(
          operator_id: nil,
          lease_expiry: nil,
          lease_rate: nil,
        )
    end

    def seats_elevation_range_constant(elevation)
      takeoff_elevation_multiplier(elevation) * 0.5 * aircraft_model.takeoff_distance * takeoff_seats_component
    end

    def seats_fit_on_plane
      if floor_space_used > aircraft_model.floor_space
        errors.add(:seats, "require more total floor space than available on airplane")
      end
    end

    def scrap_value
      value_at_age((end_of_useful_life - construction_date).to_i)
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

    def total_flights
      airplane_routes.map{ |r| r.frequencies * 2 }.sum
    end

    def update_configuration(new_economy, new_premium_economy, new_business)
      new_configuratin_cost = cost_to_reconfigure(new_economy, new_premium_economy, new_business)

      assign_attributes(
        business_seats: new_business,
        premium_economy_seats: new_premium_economy,
        economy_seats: new_economy,
        construction_date: if built? then construction_date else [construction_date, game.current_date + days_to_reconfigure(new_business + new_premium_economy + new_economy)].max end,
      )

      airplane_routes.each do |airplane_route|
        airplane_route.assign_attributes(
          block_time_mins: (round_trip_block_time(airplane_route.route.distance) * airplane_route.frequencies).round,
        )
      end
      validate

      if operator.cash_on_hand < new_configuratin_cost
        errors.add(:airline, "does not have enough cash on hand to reconfigure")
      end

      errors.none? &&
        save &&
        operator.update!(cash_on_hand: operator.cash_on_hand - new_configuratin_cost) &&
        airplane_routes.each(&:recalculate_profits_and_block_time) && true
    end

    def update_downstream_block_times
      airplane_routes.each do |route|
        route.update(block_time_mins: (route.frequencies * round_trip_block_time(route.route.distance)).round)
      end
    end

    def value
      value_at_age(age_in_days)
    end

    def value_component_left_on_lease
      daily_lease_expense * days_left_on_lease / lease_premium
    end
end
