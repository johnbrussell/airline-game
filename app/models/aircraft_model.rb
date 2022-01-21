class AircraftModel < ApplicationRecord
  validates :name, presence: true
  validates :production_start_year, presence: true
  validates :production_start_year, numericality: { greater_than_or_equal_to: 1914 }
  validates :floor_space, presence: true
  validates :floor_space, numericality: { greater_than: 0 }
  validates :max_range, presence: true
  validates :max_range, numericality: { greater_than: 0 }
  validates :fuel_burn, presence: true
  validates :fuel_burn, numericality: { greater_than: 0 }
  validates :speed, presence: true
  validates :speed, numericality: { greater_than: 0 }
  validates :num_pilots, presence: true
  validates :num_pilots, numericality: { greater_than: 0 }
  validates :num_flight_attendants, presence: true
  validates :num_flight_attendants, numericality: { greater_than_or_equal_to: 0 }
  validates :price, presence: true
  validates :price, numericality: { greater_than: 0 }
  validates :takeoff_distance, presence: true
  validates :takeoff_distance, numericality: { greater_than: 0 }
  validates :useful_life, presence: true
  validates :useful_life, numericality: { greater_than: 0 }

  belongs_to :family, class_name: "AircraftFamily", foreign_key: "aircraft_family_id"

  DAYS_PER_YEAR = 365.24
  MIN_TAXI_TIME_MINS = 3
  PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE = 0.03
  SLOW_DISTANCE_TIME_MINS = 30
  SLOW_SPEED = 1/2.0

  def daily_value_retention
    PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE ** (1 / (DAYS_PER_YEAR * useful_life))
  end

  def flight_time_mins(distance)
    flight_time_mins_exc_taxi(distance) + 2 * MIN_TAXI_TIME_MINS
  end

  def max_business_seats
    floor_space / Airplane::BUSINESS_SEAT_SIZE
  end

  def max_economy_seats
    floor_space / Airplane::ECONOMY_SEAT_SIZE
  end

  def max_premium_economy_seats
    floor_space / Airplane::PREMIUM_ECONOMY_SEAT_SIZE
  end

  private

    def flight_time_mins_exc_taxi(distance)
      if distance <= slow_distance
        distance.to_f / speed * 60 * 2
      else
        (distance - slow_distance).to_f / speed * 60 + SLOW_DISTANCE_TIME_MINS
      end
    end

    def slow_distance
      speed * SLOW_SPEED * SLOW_DISTANCE_TIME_MINS / 60.0
    end
end
