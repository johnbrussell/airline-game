module Populatable
  extend ActiveSupport::Concern

  include Demandable

  private

    def airport_population
      Calculation::AirportPopulation.new(@destination, @current_date).population
    end
end
