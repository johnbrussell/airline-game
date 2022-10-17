class RelativeDemand < ApplicationRecord
  validates :business, presence: true
  validates :business, numericality: { greater_than_or_equal_to: 0 }
  validates :government, presence: true
  validates :government, numericality: { greater_than_or_equal_to: 0 }
  validates :last_measured, presence: true
  validates :leisure, presence: true
  validates :leisure, numericality: { greater_than_or_equal_to: 0 }
  validates :pct_business, presence: true
  validates :pct_business, numericality: { greater_than_or_equal_to: 0 }
  validates :pct_economy, presence: true
  validates :pct_economy, numericality: { greater_than_or_equal_to: 0 }
  validates :pct_premium_economy, presence: true
  validates :pct_premium_economy, numericality: { greater_than_or_equal_to: 0 }
  validates :tourist, presence: true
  validates :tourist, numericality: { greater_than_or_equal_to: 0 }
  validates :last_measured, uniqueness: { scope: [:origin_market_id, :destination_market_id, :origin_airport_iata, :destination_airport_iata] }

  belongs_to :origin_market, class_name: "Market"
  belongs_to :destination_market, class_name: "Market"
  belongs_to :origin_airport, class_name: "Airport", foreign_key: :origin_airport_iata, primary_key: :iata, optional: true
  belongs_to :destination_airport, class_name: "Airport", foreign_key: :destination_airport_iata, primary_key: :iata, optional: true

  def self.calculate(date, origin_airport, destination_airport, origin_market, destination_market)
    relative_demand = RelativeDemand.find_by(
      origin_market_id: origin_market.id,
      destination_market_id: destination_market.id,
      origin_airport_iata: origin_airport ? origin_airport.iata : "",
      destination_airport_iata: destination_airport ? destination_airport.iata : "",
      last_measured: date,
    )
    if relative_demand.nil?
      calculator = Calculation::RelativeDemand.new(date, origin_airport, destination_airport, origin_market, destination_market)
      RelativeDemand.create!(
        origin_market_id: origin_market.id,
        destination_market_id: destination_market.id,
        origin_airport_iata: origin_airport ? origin_airport.iata : "",
        destination_airport_iata: destination_airport ? destination_airport.iata : "",
        last_measured: date,
        business: calculator.business,
        government: calculator.government,
        leisure: calculator.leisure,
        tourist: calculator.tourist,
        pct_business: 1 / 3.0,
        pct_economy: 1 / 3.0,
        pct_premium_economy: 1 / 3.0,
      )
    else
      relative_demand
    end
  end
end
