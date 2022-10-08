class RouteDemand < ApplicationRecord
  validates :business, numericality: { greater_than_or_equal_to: 0 }
  validates :business, presence: true
  validates :destination_iata, presence: true
  validates :exclusive_business, numericality: { greater_than_or_equal_to: 0 }
  validates :exclusive_business, presence: true
  validates :exclusive_government, numericality: { greater_than_or_equal_to: 0 }
  validates :exclusive_government, presence: true
  validates :exclusive_leisure, numericality: { greater_than_or_equal_to: 0 }
  validates :exclusive_leisure, presence: true
  validates :exclusive_tourist, numericality: { greater_than_or_equal_to: 0 }
  validates :exclusive_tourist, presence: true
  validates :government, numericality: { greater_than_or_equal_to: 0 }
  validates :government, presence: true
  validates :leisure, numericality: { greater_than_or_equal_to: 0 }
  validates :leisure, presence: true
  validates :origin_iata, presence: true
  validates :tourist, numericality: { greater_than_or_equal_to: 0 }
  validates :tourist, presence: true

  def self.calculate(date, origin_airport, destination_airport)
    route_demand = find_by(origin_iata: origin_airport.iata, destination_iata: destination_airport.iata, year: date.year)
    if route_demand.nil?
      business = business_demand(origin_airport, destination_airport, date)
      government = government_demand(origin_airport, destination_airport, date)
      leisure = leisure_demand(origin_airport, destination_airport, date)
      tourist = tourist_demand(origin_airport, destination_airport, date)
      exclusive_ratio = destination_airport.exclusive_catchment / (destination_airport.exclusive_catchment + destination_airport.market.shared_catchment).to_f
      create!(
        year: date.year,
        origin_iata: origin_airport.iata,
        destination_iata: destination_airport.iata,
        business: business,
        exclusive_business: business * exclusive_ratio,
        exclusive_government: government * exclusive_ratio,
        exclusive_leisure: leisure * exclusive_ratio,
        exclusive_tourist: tourist * exclusive_ratio,
        government: government,
        leisure: leisure,
        tourist: tourist,
      )
    else
      route_demand
    end
  end

  private

    def self.business_demand(origin_airport, destination_airport, date)
      Calculation::ResidentDemand.new(origin_airport, destination_airport, date).business_demand
    end

    def self.government_demand(origin_airport, destination_airport, date)
      Calculation::GovernmentDemand.new(origin_airport, destination_airport, date).demand
    end

    def self.leisure_demand(origin_airport, destination_airport, date)
      Calculation::ResidentDemand.new(origin_airport, destination_airport, date).leisure_demand
    end

    def self.tourist_demand(origin_airport, destination_airport, date)
      Calculation::TouristDemand.new(origin_airport, destination_airport, date).demand
    end
end
