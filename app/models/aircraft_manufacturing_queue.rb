class AircraftManufacturingQueue < ApplicationRecord
  belongs_to :game
  has_many :airplanes
end
