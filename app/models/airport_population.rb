class AirportPopulation < ApplicationRecord
  validates :year, presence: true
  validates :government, presence: true
  validates :government, numericality: { greater_than_or_equal_to: 0 }
  validates :population, presence: true
  validates :population, numericality: { greater_than: 0 }
  validates :tourists, presence: true
  validates :tourists, numericality: { greater_than: 0 }

  def self.calculate(airport, date)
    airport_population = find_by(airport_id: airport.id, year: date.year)
    if airport_population.nil?
      calculator = Calculation::AirportPopulation.new(airport, date)
      create!(
        airport_id: airport.id,
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
