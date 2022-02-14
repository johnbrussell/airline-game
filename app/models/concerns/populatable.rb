module Populatable
  extend ActiveSupport::Concern

  include Demandable

  private

    def airport_population
      AirportPopulation.calculate(@destination, @current_date).population
    end
end
