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

    def domestic?
      origin_market.country == destination_market.country
    end

    def flight_distance
      @flight_distance ||= Calculation::Distance.between_airports(@origin, @destination)
    end

    def origin_market
      @origin_market ||= @origin.market
    end

    def same_country_group?
      origin_market.country_group == destination_market.country_group
    end
end
