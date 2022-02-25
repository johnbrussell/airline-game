module Populatable
  extend ActiveSupport::Concern

  include Demandable

  private

    def airport_population(current_date)
      AirportPopulation.calculate(@destination, current_date).population
    end
end
