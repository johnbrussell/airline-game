class Calculation::TouristDemand
  include Populatable

  def demand
    if origin_market == destination_market
      0
    else
      airport_population / 100.0 * distance_demand * border_multiplier
    end
  end

  private

    def border_multiplier
      domestic? ? 1 : 1/3.0
    end

    def demand_curve
      @demand_curve ||= Calculation::DemandCurve.new(:leisure)
    end

    def distance_demand
      if origin_market.is_island
        demand_curve.relative_demand_island(distance)
      else
        demand_curve.relative_demand(distance)
      end
    end
end
