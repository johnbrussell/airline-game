class MarketPopulation < ApplicationRecord
  validates :year, presence: true
  validates :government, presence: true
  validates :government, numericality: { greater_than_or_equal_to: 0 }
  validates :population, presence: true
  validates :population, numericality: { greater_than: 0 }
  validates :tourists, presence: true
  validates :tourists, numericality: { greater_than: 0 }

  def self.calculate(market, date)
    market_population = find_by(market_id: market.id, year: date.year)
    if market_population.nil?
      calculator = Calculation::MarketPopulation.new(market, date)
      create!(
        market_id: market.id,
        year: date.year,
        government: calculator.government_workers,
        population: calculator.population,
        tourists: calculator.tourists,
      )
    else
      market_population
    end
  end
end
