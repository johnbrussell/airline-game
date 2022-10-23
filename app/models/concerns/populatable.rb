module Populatable
  extend ActiveSupport::Concern

  include Demandable

  def initialize(origin, destination, date, destination_airport_population = nil)
    @airport_population = destination_airport_population&.population
    super(origin, destination, date)
  end

  private

    def airport_population
      @airport_population ||= AirportPopulation.calculate(@destination, @current_date).population
    end
end
