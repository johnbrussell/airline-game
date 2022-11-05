class RouteDollars < ApplicationRecord
  validates :business, presence: true
  validates :business, numericality: { greater_than_or_equal_to: 0 }
  validates :economy, presence: true
  validates :economy, numericality: { greater_than_or_equal_to: 0 }
  validates :premium_economy, presence: true
  validates :premium_economy, numericality: { greater_than_or_equal_to: 0 }
  validates :date, uniqueness: { scope: [:origin_market_id, :destination_market_id, :origin_airport_iata, :destination_airport_iata] }
  validates :distance, presence: true
  validates :distance, numericality: { greater_than_or_equal_to: 0 }

  belongs_to :origin_market, class_name: "Market"
  belongs_to :destination_market, class_name: "Market"
  belongs_to :origin_airport, class_name: "Airport", foreign_key: :origin_airport_iata, primary_key: :iata, optional: true
  belongs_to :destination_airport, class_name: "Airport", foreign_key: :destination_airport_iata, primary_key: :iata, optional: true

  def self.between_markets(market_1, market_2, date)
    self.market_airports(market_1).product(self.market_airports(market_2)).flat_map do |airport_1, airport_2|
      [
        self.calculate(date, market_1, market_2, airport_1, airport_2),
        self.calculate(date, market_2, market_1, airport_2, airport_1),
      ]
    end
  end

  def self.calculate(date, origin_market, destination_market, origin_airport, destination_airport)
    existing = find_by(date: date, origin_market: origin_market, destination_market: destination_market, origin_airport: origin_airport || "", destination_airport: destination_airport || "")
    if existing.nil?
      RelativeDemand.calculate_between_markets(date, origin_market, destination_market)
      calculator = Calculation::RouteDollars.new(date, origin_market, destination_market, origin_airport, destination_airport)
      create!(
        origin_market: origin_market,
        destination_market: destination_market,
        origin_airport_iata: origin_airport&.iata || "",
        destination_airport_iata: destination_airport&.iata || "",
        date: date,
        distance: calculator.distance,
        business: calculator.business_class_dollars,
        economy: calculator.economy_class_dollars,
        premium_economy: calculator.premium_economy_class_dollars,
      )
    else
      existing
    end
  end

  private

    def self.market_airports(market)
      market.airports.to_a + [nil]
    end
end
