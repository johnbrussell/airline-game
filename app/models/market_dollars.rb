class MarketDollars < ApplicationRecord
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
    existing = find_by(
      market: market,
      year: date.year,
    )
    if existing.nil?
      calculator = Calculation::MarketDollars.new(market.airports.first, date, market)
      create!(
        market: market,
        year: date.year,
        business: calculator.business,
        government: calculator.government,
        leisure: calculator.leisure,
        tourist: calculator.tourist,
      )
    else
      existing
    end
  end
end
