class Calculation::TouristDemand
  include Populatable

  def demand
    if origin_market == destination_market
      0
    else
      airport_population / 100.0 * distance_demand(:leisure) * border_multiplier
    end
  end

  private

    def border_multiplier
      domestic? ? 1 : 1/3.0
    end

    def distance_demand(type)
      if origin_market.is_island
        Calculation::DemandCurve.new(distance, type).relative_demand_island
      else
        Calculation::DemandCurve.new(distance, type).relative_demand
      end
    end
end
