module Populatable
  extend ActiveSupport::Concern

  include Demandable

  private

    def market_population
      @market_population ||= MarketPopulation.calculate(@destination.market, @current_date).population
    end
end
