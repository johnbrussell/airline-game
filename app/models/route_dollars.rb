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

  validate :markets_alphabetized

  WEEKS_PER_YEAR = 365.25 / 7

  belongs_to :origin_market, class_name: "Market"
  belongs_to :destination_market, class_name: "Market"
  belongs_to :origin_airport, class_name: "Airport", foreign_key: :origin_airport_iata, primary_key: :iata, optional: true
  belongs_to :destination_airport, class_name: "Airport", foreign_key: :destination_airport_iata, primary_key: :iata, optional: true

  def self.between_markets(market_1, market_2, date)
    self.market_airports(market_1).product(self.market_airports(market_2)).map do |airport_1, airport_2|
      self.calculate(date, market_1, market_2, airport_1, airport_2)
    end
  end

  def self.calculate(date, origin_market, destination_market, origin_airport, destination_airport)
    if origin_market.name <= destination_market.name
      self.calculate_with_alphabetical_markets(date, origin_market, destination_market, origin_airport, destination_airport)
    else
      self.calculate_with_alphabetical_markets(date, destination_market, origin_market, destination_airport, origin_airport)
    end
  end

  def inertia_service
    @inertia_service ||= Calculation::InertiaRouteService.new(self)
  end

  private

    def self.calculate_with_alphabetical_markets(date, origin_market, destination_market, origin_airport, destination_airport)
      existing = find_by(
        date: date,
        origin_market: origin_market,
        destination_market: destination_market,
        origin_airport: origin_airport&.iata || "",
        destination_airport: destination_airport&.iata || "",
      )
      if existing.nil?
        RelativeDemand.calculate_between_markets(date, origin_market, destination_market)
        RelativeDemand.calculate_between_markets(date, destination_market, origin_market)
        calculator_1 = Calculation::RouteDollars.new(date, origin_market, destination_market, origin_airport, destination_airport)
        calculator_2 = Calculation::RouteDollars.new(date, destination_market, origin_market, destination_airport, origin_airport)
        # Dollars are total dollars in both directions per week
        create!(
          origin_market: origin_market,
          destination_market: destination_market,
          origin_airport_iata: origin_airport&.iata || "",
          destination_airport_iata: destination_airport&.iata || "",
          date: date,
          distance: calculator_1.distance,
          business: (calculator_1.business_class_dollars + calculator_2.business_class_dollars) / WEEKS_PER_YEAR,
          economy: (calculator_1.economy_class_dollars + calculator_2.economy_class_dollars) / WEEKS_PER_YEAR,
          premium_economy: (calculator_1.premium_economy_class_dollars + calculator_2.premium_economy_class_dollars) / WEEKS_PER_YEAR,
        )
      else
        existing
      end
    end

    def self.market_airports(market)
      market.airports.to_a + [nil]
    end

    def markets_alphabetized
      if origin_market.name > destination_market.name
        errors.add(:origin_market, "name must be alphabetically before destination_market name")
      end
    end
end
