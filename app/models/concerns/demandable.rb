module Demandable
  extend ActiveSupport::Concern

  def initialize(origin, destination, current_date, opts = {})
    @origin = origin
    @destination = destination
    @current_date = current_date

    opts.each do |opt, value|
      self.instance_variable_set("@#{opt}".to_sym, value)
    end
  end

  private

    def between_rival_countries?
      @between_rival_countries ||= RivalCountryGroup.rivals?(origin_market.country_group, destination_market.country_group)
    end

    def destination_market
      @destination_market ||= @destination.market
    end

    def domestic?
      origin_market.country == destination_market.country
    end

    def flight_distance
      @flight_distance ||= Calculation::Distance.between_airports(@origin, @destination)
    end

    def island_exception_exists?
      @island_exception_exists ||= IslandException.excepted?(origin_market, destination_market)
    end

    def origin_market
      @origin_market ||= @origin.market
    end

    def same_country_group?
      origin_market.country_group == destination_market.country_group
    end
end
