class Calculation::TouristDemand
  include Populatable

  def demand
    if origin_market == destination_market || RivalCountryGroup.rivals?(origin_market.country_group, destination_market.country_group)
      0
    else
      market_population / 100.0 * distance_demand * border_multiplier
    end
  end

  private

    def border_multiplier
      if domestic?
        1
      elsif same_country_group?
        2/3.0
      else
        1/3.0
      end
    end

    def demand_curve
      @demand_curve ||= Calculation::DemandCurve.new(:leisure)
    end

    def distance_demand
      if origin_market.is_island  && !island_exception_exists?
        demand_curve.relative_demand_island(flight_distance)
      else
        demand_curve.relative_demand(flight_distance)
      end
    end
end
