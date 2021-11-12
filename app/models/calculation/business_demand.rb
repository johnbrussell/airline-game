class Calculation::BusinessDemand
  include Islandable
  include Populatable

  def demand
    if origin_market == destination_market
      0
    else
      airport_population / 100.0 * distance_demand * border_multiplier * island_multipler
    end
  end

  private

    def border_multiplier
      if origin_market.is_island
        domestic? ? 1 : 1/12.0
      else
        domestic? ? 1 : 1/4.0
      end
    end

    def distance_demand
      if origin_market.is_island
        Calculation::DemandCurve.new(distance, :business).relative_demand_island
      else
        Calculation::DemandCurve.new(distance, :business).relative_demand
      end
    end
end
