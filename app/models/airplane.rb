class Airplane < ApplicationRecord
  validates :business_seats, presence: true
  validates :business_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :construction_date, presence: true
  validates :economy_seats, presence: true
  validates :economy_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :end_of_useful_life, presence: true
  validates :premium_economy_seats, presence: true
  validates :premium_economy_seats, numericality: { greater_than_or_equal_to: 0 }

  validate :operator_changes_appropriately, unless: :new_record?

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
  PERCENT_OF_USEFUL_LIFE_LEASED_FOR_FULL_VALUE = 0.4

  def has_operator?
    operator_id.present?
  end

  def lease_rate_per_day(lease_in_days)
    (value - value_at_age(age_in_days + lease_in_days)) * lease_premium / lease_in_days
  end

  def new_plane_payment
    value / 2.0
  end

  def purchase_price
    value
  end

  private

    def age_in_days
      (game.current_date - construction_date).to_i
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

    def value
      value_at_age([age_in_days, 0].max)
    end

    def value_at_age(days)
      model.price * model.daily_value_retention ** days
    end
end
