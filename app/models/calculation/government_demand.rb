class Calculation::GovernmentDemand
  include Islandable
  include Populatable

  def demand
    if origin_market == destination_market || !origin_market.is_national_capital || between_rival_countries?
      0
    else
      market_population / 100.0 * distance_demand * border_multiplier * island_multipler
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
      if origin_market.is_island && !island_exception_exists?
        demand_curve.relative_demand_island(flight_distance)
      else
        demand_curve.relative_demand(flight_distance)
      end
    end
end
