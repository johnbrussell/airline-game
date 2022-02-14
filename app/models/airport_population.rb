class AirportPopulation < ApplicationRecord
  validates :year, presence: true
  validates :government, presence: true
  validates :government, numericality: { greater_than_or_equal_to: 0 }
  validates :population, presence: true
  validates :population, numericality: { greater_than: 0 }
  validates :tourists, presence: true
  validates :tourists, numericality: { greater_than: 0 }

  belongs_to :airport

  def self.calculate(airport, date)
    airport_population = find_by(airport: airport, year: date.year)
    if airport_population.nil?
      calculator = Calculation::AirportPopulation.new(airport, date.year)
      create!(
        airport: airport,
        year: date.year,
        government: calculator.government_workers,
        population: calculator.population,
        tourists: calculator.tourists,
      )
    else
      airport_population
    end
  end
end
