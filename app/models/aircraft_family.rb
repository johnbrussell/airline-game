class AircraftFamily < ApplicationRecord
  validates :name, presence: true
  validates :manufacturer, presence: true
end
