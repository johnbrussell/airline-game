class TotalMarketDemand < ApplicationRecord
  validates :business, presence: true
  validates :business, numericality: { greater_than_or_equal_to: 0 }
  validates :government, presence: true
  validates :government, numericality: { greater_than_or_equal_to: 0 }
  validates :leisure, presence: true
  validates :leisure, numericality: { greater_than_or_equal_to: 0 }
  validates :tourist, presence: true
  validates :tourist, numericality: { greater_than_or_equal_to: 0 }
  validates :year, presence: true

  belongs_to :market

  def self.calculate(market, date)
    total_market_demand = find_by(
      market: market,
      year: date.year,
    )
    if total_market_demand.nil?
      relative_demands = self.total_relative_demands(market, date)
      create!(
        market: market,
        year: date.year,
        business: relative_demands[:business],
        government: relative_demands[:government],
        leisure: relative_demands[:leisure],
        tourist: relative_demands[:tourist],
      )
    else
      total_market_demand
    end
  end

  private

    def self.market_airports(market)
      market.airports + [nil]
    end

    def self.total_relative_demands(origin_market, date)
      totals = {
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
      }
      Market.find_in_batches do |batch|
        batch.each do |destination_market|
          self.market_airports(destination_market).each do |destination_airport|
            self.market_airports(origin_market).each do |origin_airport|
              relative_demand = RelativeDemand.most_recent_or_create(date, origin_airport, destination_airport, origin_market, destination_market)
              totals[:business] += relative_demand.business
              totals[:government] += relative_demand.government
              totals[:leisure] += relative_demand.leisure
              totals[:tourist] += relative_demand.tourist
            end
          end
        end
      end
      totals
    end
end
