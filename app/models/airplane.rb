class Airplane < ApplicationRecord
  validates :business_seats, presence: true
  validates :business_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :construction_date, presence: true
  validates :economy_seats, presence: true
  validates :economy_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :end_of_useful_life, presence: true
  validates :premium_economy_seats, presence: true
  validates :premium_economy_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :lease_rate, numericality: { greater_than: 0 }, allow_nil: true

  validate :operator_changes_appropriately, unless: :new_record?
  validate :seats_fit_on_plane

  belongs_to :aircraft_manufacturing_queue
  belongs_to :aircraft_model

  delegate :game, :to => :aircraft_manufacturing_queue

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
  MAX_LEASE_DAYS = 3652
  MIN_PERCENT_OF_LEASE_NEEDED_AS_CASH_ON_HAND_TO_LEASE = 0.08
  PERCENT_OF_USEFUL_LIFE_LEASED_FOR_FULL_VALUE = 0.4

  def built?
    construction_date <= aircraft_manufacturing_queue.game.current_date
  end

  def has_operator?
    operator_id.present?
  end

  def lease(airline, length_in_days, business_seats, premium_economy_seats, economy_seats)
    lease_start_date = built? ? aircraft_manufacturing_queue.game.current_date : construction_date
    if built?
      assign_attributes(lease_rate: lease_rate_per_day(length_in_days.to_i), lease_expiry: lease_start_date + length_in_days.to_i.days)
      airline.assign_attributes(cash_on_hand: airline.cash_on_hand - lease_rate_per_day(length_in_days.to_i))
    else
      assign_attributes(
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

  def new_plane_payment
    value / 2.0
  end

  def purchase(airline, business_seats, premium_economy_seats, economy_seats)
    if !built?
      assign_attributes(
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

  private

    def age_in_days
      [(game.current_date - construction_date).to_i, 0].max
    end

    def lease_premium
      model.price / (model.price - value_at_age(PERCENT_OF_USEFUL_LIFE_LEASED_FOR_FULL_VALUE * model.useful_life * AircraftModel::DAYS_PER_YEAR))
    end

    def model
      @model ||= AircraftModel.find_by(id: aircraft_model_id)
    end

    def operator_changes_appropriately
      copy = Airplane.find(id)
      if copy.operator_id != operator_id && copy.operator_id.present? && operator_id.present?
        errors.add(:operator_id, "cannot be changed from one airline directly to another; must be put on the market first")
      end
    end

    def purchase_payment
      built? ? purchase_price : new_plane_payment
    end

    def seats_fit_on_plane
      if ECONOMY_SEAT_SIZE * economy_seats + PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + BUSINESS_SEAT_SIZE * business_seats > aircraft_model.floor_space
        errors.add(:seats, "require more total floor space than available on airplane")
      end
    end

    def value
      value_at_age(age_in_days)
    end

    def value_at_age(days)
      model.price * model.daily_value_retention ** days
    end
end
