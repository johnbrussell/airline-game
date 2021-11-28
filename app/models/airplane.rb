class Airplane < ApplicationRecord
  validates :business_seats, presence: true
  validates :business_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :construction_date, presence: true
  validates :economy_seats, presence: true
  validates :economy_seats, numericality: { greater_than_or_equal_to: 0 }
  validates :premium_economy_seats, presence: true
  validates :premium_economy_seats, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :aircraft_manufacturing_queue

  delegate :game, :to => :aircraft_manufacturing_queue

  ECONOMY_SEAT_SIZE = 28 * 17

  def has_operator?
    operator_id.present?
  end

  def purchase_price
    value
  end

  private

    def age_in_days
      (game.current_date - construction_date).to_i
    end

    def model
      @model ||= AircraftModel.find_by(id: aircraft_model_id)
    end

    def value
      model.price * model.daily_value_retention ** [age_in_days, 0].max
    end
end
