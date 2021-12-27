class Airplane < ApplicationRecord
  validates :business_seats, presence: true
  validates :business_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :construction_date, presence: true
  validates :economy_seats, presence: true
  validates :economy_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :end_of_useful_life, presence: true
  validates :premium_economy_seats, presence: true
  validates :premium_economy_seats, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :aircraft_manufacturing_queue
  belongs_to :aircraft_model

  delegate :game, :to => :aircraft_manufacturing_queue

  ECONOMY_SEAT_SIZE = 28 * 17
  PERCENT_OF_USEFUL_LIFE_LEASED_FOR_FULL_VALUE = 0.4

  def has_operator?
    operator_id.present?
  end

  def lease_rate_per_day(lease_in_days)
    (value - value_at_age(age_in_days + lease_in_days)) * lease_premium / lease_in_days
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

    def value
      value_at_age([age_in_days, 0].max)
    end

    def value_at_age(days)
      model.price * model.daily_value_retention ** days
    end
end
