class AirlineRoute < ApplicationRecord
  validates :economy_price, presence: true
  validates :economy_price, numericality: { greater_than: 0 }
  validates :premium_economy_price, presence: true
  validates :premium_economy_price, numericality: { greater_than: 0 }
  validates :business_price, presence: true
  validates :business_price, numericality: { greater_than: 0 }
  validates :origin_airport_id, presence: true
  validates :destination_airport_id, presence: true
  validate :airports_alphabetized

  has_many :airplane_routes
  has_many :airplanes, through: :airplane_routes
  belongs_to :origin_airport, class_name: "Airport"
  belongs_to :destination_airport, class_name: "Airport"

  private

    def airports_alphabetized
      if Airport.find(destination_airport_id).iata <= Airport.find(origin_airport_id).iata
        errors.add(:destination_airport_id, "must correspond to an airport with iata alphabetically after origin airport's iata")
      end
    end
end
