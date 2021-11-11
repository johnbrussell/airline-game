module Demandable
  extend ActiveSupport::Concern

  def initialize(origin, destination, current_date)
    @origin = origin
    @destination = destination
    @current_date = current_date
  end

  private

    def destination_market
      @destination_market ||= @destination.market
    end

    def distance
      Calculation::Distance.between_airports(@origin, @destination)
    end

    def domestic?
      origin_market.country == destination_market.country
    end

    def origin_market
      @origin_market ||= @origin.market
    end
end
