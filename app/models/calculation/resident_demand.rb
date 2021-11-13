class Calculation::ResidentDemand
  include Islandable
  include Populatable

  def business_demand
    raw_demand(:business)
  end

  def leisure_demand
    raw_demand(:leisure)
  end

  private

    def border_multiplier
      if origin_market.is_island
        domestic? ? 1 : 1/12.0
      else
        domestic? ? 1 : 1/4.0
      end
    end

    def distance_demand(type)
      if origin_market.is_island
        Calculation::DemandCurve.new(type).relative_demand_island(distance)
      else
        Calculation::DemandCurve.new(type).relative_demand(distance)
      end
    end

    def raw_demand(type)
      if origin_market == destination_market
        0
      else
        airport_population / 100.0 * distance_demand(type) * border_multiplier * island_multipler
      end
    end
end
