class GlobalDemand < ApplicationRecord
  validates :business, numericality: { greater_than_or_equal_to: 0 }
  validates :business, presence: true
  validates :government, numericality: { greater_than_or_equal_to: 0 }
  validates :government, presence: true
  validates :leisure, numericality: { greater_than_or_equal_to: 0 }
  validates :leisure, presence: true
  validates :tourist, numericality: { greater_than_or_equal_to: 0 }
  validates :tourist, presence: true
  validates :year, presence: true

  belongs_to :airport

  def self.calculate(date, origin_airport)
    global_demand = find_by(airport_id: origin_airport.id, year: date.year)
    if global_demand.nil?
      create!(
        airport_id: origin_airport.id,
        year: date.year,
        business: market_business_demands(origin_airport, date).sum,
        government: market_government_demands(origin_airport, date).sum,
        leisure: market_leisure_demands(origin_airport, date).sum,
        tourist: market_tourist_demands(origin_airport, date).sum,
      )
    else
      global_demand
    end
  end

  private

    def self.market_business_demands(origin_airport, date)
      valid_destination_markets(origin_airport).map do |market|
        Calculation::TotalMarketDemand.business(origin_airport, market, date)
      end
    end

    def self.market_government_demands(origin_airport, date)
      valid_destination_markets(origin_airport).map do |market|
        Calculation::TotalMarketDemand.government(origin_airport, market, date)
      end
    end

    def self.market_leisure_demands(origin_airport, date)
      valid_destination_markets(origin_airport).map do |market|
        Calculation::TotalMarketDemand.leisure(origin_airport, market, date)
      end
    end

    def self.market_tourist_demands(origin_airport, date)
      valid_destination_markets(origin_airport).map do |market|
        Calculation::TotalMarketDemand.tourist(origin_airport, market, date)
      end
    end

    def self.valid_destination_markets(origin_airport)
      Market.where("country_group NOT IN (?)", RivalCountryGroup.all_rivals(origin_airport.market.country_group).join(","))
    end
end
