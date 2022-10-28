class RelativeDemand < ApplicationRecord
  validates :business, presence: true
  validates :business, numericality: { greater_than_or_equal_to: 0 }
  validates :distance, presence: true
  validates :distance, numericality: { greater_than_or_equal_to: 0 }
  validates :government, presence: true
  validates :government, numericality: { greater_than_or_equal_to: 0 }
  validates :last_measured, presence: true
  validates :leisure, presence: true
  validates :leisure, numericality: { greater_than_or_equal_to: 0 }
  validates :tourist, presence: true
  validates :tourist, numericality: { greater_than_or_equal_to: 0 }
  validates :last_measured, uniqueness: { scope: [:origin_market_id, :destination_market_id, :origin_airport_iata, :destination_airport_iata] }

  belongs_to :origin_market, class_name: "Market"
  belongs_to :destination_market, class_name: "Market"
  belongs_to :origin_airport, class_name: "Airport", foreign_key: :origin_airport_iata, primary_key: :iata, optional: true
  belongs_to :destination_airport, class_name: "Airport", foreign_key: :destination_airport_iata, primary_key: :iata, optional: true

  MAXIMUM_AGE_OF_VALID_RELATIVE_DEMAND = 1.year

  def self.calculate(date, origin_airport, destination_airport, origin_market, destination_market)
    relative_demand = RelativeDemand.find_by(
      origin_market_id: origin_market.id,
      destination_market_id: destination_market.id,
      origin_airport_iata: origin_airport ? origin_airport.iata : "",
      destination_airport_iata: destination_airport ? destination_airport.iata : "",
      last_measured: date,
    )
    if relative_demand.nil?
      self.create_new(date, origin_airport, destination_airport, origin_market, destination_market)
    else
      relative_demand
    end
  end

  def self.calculate_between_markets(date, origin_market, destination_market)
    self.market_airports(origin_market).each do |origin_airport|
      self.market_airports(destination_market).each do |destination_airport|
        self.calculate(date, origin_airport, destination_airport, origin_market, destination_market)
      end
    end
  end

  def self.most_recent(date, origin_airport, destination_airport, origin_market, destination_market)
    RelativeDemand
      .where('last_measured <= ?', date)
      .where('last_measured > ?', date - MAXIMUM_AGE_OF_VALID_RELATIVE_DEMAND)
      .where(
        origin_market: origin_market,
        destination_market: destination_market,
        origin_airport_iata: origin_airport&.iata || "",
        destination_airport_iata: destination_airport&.iata || ""
      )
      .max_by(&:last_measured)
  end

  def self.most_recent_or_create(date, origin_airport, destination_airport, origin_market, destination_market)
    most_recent = self.most_recent(date, origin_airport, destination_airport, origin_market, destination_market)
    if most_recent.nil?
      self.create_new(date, origin_airport, destination_airport, origin_market, destination_market)
    else
      most_recent
    end
  end

  def self.most_recent_or_initialize(date, origin_airport, destination_airport, origin_market, destination_market)
    most_recent = self.most_recent(date, origin_airport, destination_airport, origin_market, destination_market)
    if most_recent.nil?
      self.initialize_new(date, origin_airport, destination_airport, origin_market, destination_market)
    else
      most_recent
    end
  end

  private

    def self.create_new(date, origin_airport, destination_airport, origin_market, destination_market)
      self.initialize_new(date, origin_airport, destination_airport, origin_market, destination_market).tap(&:save)
    end

    def self.initialize_new(date, origin_airport, destination_airport, origin_market, destination_market)
      calculator = Calculation::RelativeDemand.new(date, origin_airport, destination_airport, origin_market, destination_market)
      RelativeDemand.new(
        origin_market_id: origin_market.id,
        destination_market_id: destination_market.id,
        origin_airport_iata: origin_airport ? origin_airport.iata : "",
        destination_airport_iata: destination_airport ? destination_airport.iata : "",
        last_measured: date,
        business: calculator.business,
        government: calculator.government,
        leisure: calculator.leisure,
        tourist: calculator.tourist,
        distance: calculator.distance,
      )
    end

    def self.market_airports(market)
      market.airports + [nil]
    end
end
