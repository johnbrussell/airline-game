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
  PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE = 0.03

  def daily_value_retention
    PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE ** (1 / (DAYS_PER_YEAR * useful_life))
  end
end
