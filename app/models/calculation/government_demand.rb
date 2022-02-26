class Calculation::GovernmentDemand
  include Islandable
  include Populatable

  def demand
    if origin_market == destination_market || !origin_market.is_national_capital || RivalCountryGroup.rivals?(origin_market.country_group, destination_market.country_group)
      0
    else
      airport_population / 100.0 * distance_demand * border_multiplier * island_multipler
    end
  end

  private

    def border_multiplier
      if domestic?
        1
      elsif same_country_group?
        33/100.0
      else
        1/100.0
      end
    end

    def demand_curve
      @demand_curve ||= Calculation::DemandCurve.new(:business)
    end

    def distance_demand
      if origin_market.is_island && !IslandException.excepted?(origin_market, destination_market)
        demand_curve.relative_demand_island(distance) * Calculation::InertiaRouteService.new(@origin, @destination, @date).flight_cost / 10000.0
      else
        demand_curve.relative_demand(distance) * Calculation::InertiaRouteService.new(@origin, @destination, @date).flight_cost / 10000.0
      end
    end
end
