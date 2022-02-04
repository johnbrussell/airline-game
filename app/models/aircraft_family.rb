class AircraftFamily < ApplicationRecord
  validates :name, presence: true
  validates :manufacturer, presence: true
  validates :country_group, presence: true

  has_one :production_queue, class_name: "AircraftManufacturingQueue"
end
