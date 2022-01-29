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
  validates :num_aisles, presence: true
  validates :num_aisles, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 2 }
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
  FUEL_BURN_MULTIPLE = 0.00025
  MIN_TAXI_TIME_MINS = 3
  OLD_PLANE_MAINTENANCE_PREMIUM = 3
  PERCENT_OF_NEW_VALUE_SPENT_ON_MAINTENANCE_PER_YEAR = 0.03
  PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE = 0.03
  SLOW_DISTANCE_TIME_MINS = 30
  SLOW_SPEED_MULTIPLE = 1/2.0
  VERY_SLOW_DISTANCE_TIME_MINS = 10
  VERY_SLOW_SPEED_MULTIPLE = 1/3.0

  def daily_value_retention
    PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE ** (1 / (DAYS_PER_YEAR * useful_life))
  end

  def flight_fuel_burn(distance)
    # fuel burn per minute, augmented for length of flight, times minutes of flight
    fuel_burn / 60.0 * (1 + FUEL_BURN_MULTIPLE * flight_time_mins_exc_taxi(distance)) * flight_time_mins(distance)
  end

  def flight_time_mins(distance)
    flight_time_mins_exc_taxi(distance) + 2 * MIN_TAXI_TIME_MINS
  end

  def maintenance_cost_per_day(age_in_days)
    PERCENT_OF_NEW_VALUE_SPENT_ON_MAINTENANCE_PER_YEAR * maintenance_premium(age_in_days) * price / DAYS_PER_YEAR
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
      if distance <= very_slow_distance
        distance / speed.to_f / VERY_SLOW_SPEED_MULTIPLE * 60
      elsif distance <= very_slow_distance + slow_distance
        VERY_SLOW_DISTANCE_TIME_MINS + (distance - very_slow_distance) / speed.to_f / SLOW_SPEED_MULTIPLE * 60
      else
        VERY_SLOW_DISTANCE_TIME_MINS + SLOW_DISTANCE_TIME_MINS + (distance - very_slow_distance - slow_distance) / speed.to_f * 60
      end
    end

    def maintenance_premium(age_in_days)
      (1 + OLD_PLANE_MAINTENANCE_PREMIUM * age_in_days / useful_life_days)
    end

    def slow_distance
      speed * SLOW_SPEED_MULTIPLE * SLOW_DISTANCE_TIME_MINS / 60.0
    end

    def useful_life_days
      useful_life * DAYS_PER_YEAR
    end

    def very_slow_distance
      speed * VERY_SLOW_SPEED_MULTIPLE * VERY_SLOW_DISTANCE_TIME_MINS / 60.0
    end
end
