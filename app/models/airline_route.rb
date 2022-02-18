class AirlineRoute < ApplicationRecord
  validates :economy_price, presence: true
  validates :economy_price, numericality: { greater_than: 0 }
  validates :premium_economy_price, presence: true
  validates :premium_economy_price, numericality: { greater_than: 0 }
  validates :business_price, presence: true
  validates :business_price, numericality: { greater_than: 0 }
  validates :origin_airport_id, presence: true
  validates :destination_airport_id, presence: true
  validate :airline_can_fly_route
  validate :airports_alphabetized

  has_many :airplane_routes
  has_many :airplanes, through: :airplane_routes
  belongs_to :airline
  belongs_to :origin_airport, class_name: "Airport"
  belongs_to :destination_airport, class_name: "Airport"

  delegate :iata, to: :origin_airport, prefix: true
  delegate :iata, to: :destination_airport, prefix: true

  def self.operators_of_route(origin, destination)
    AirlineRoute
      .joins(:airplane_routes)
      .joins(:airline)
      .where(origin_airport_id: origin.id, destination_airport_id: destination.id)
      .order("airlines.name")
  end

  def airplanes_available_to_add_service
    airplanes +
      Airplane
        .where(operator_id: airline.id)
        .where("airplanes.id NOT IN (?)", airplanes.map(&:id) + ["default value because empty lists cause where not in commands to always return []"])
        .neatly_sorted
        .select { |a| a.can_fly_between?(origin_airport, destination_airport) }
        .select { |a| a.has_time_to_fly?(distance) }
  end

  def distance
    @distance ||= Calculation::Distance.between_airports(origin_airport, destination_airport)
  end

  def frequencies_on_airplane(airplane)
    airplane_routes.select { |ar| ar.airplane == airplane }.sum(&:frequencies)
  end

  def total_frequencies
    airplane_routes.sum(&:frequencies)
  end

  private

    def airline_can_fly_route
      if !airline.can_fly_between?(origin_airport.market, destination_airport.market)
        errors.add(:airline, "cannot fly between these airports due to political restrictions")
      end
    end

    def airports_alphabetized
      if Airport.find(destination_airport_id).iata <= Airport.find(origin_airport_id).iata
        errors.add(:destination_airport_id, "must correspond to an airport with iata alphabetically after origin airport's iata")
      end
    end
end
