class Airport < ApplicationRecord
  belongs_to :market

  validates :iata, presence: true
  validates :exclusive_catchment, presence: true
  validates :runway, presence: true
  validates :elevation, presence: true
  validates :start_gates, presence: true
  validates :easy_gates, presence: true
  validates :latitude, presence: true
  validates :longitude, presence: true
end
