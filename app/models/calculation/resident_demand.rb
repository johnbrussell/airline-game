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
      if origin_market.is_island && !island_exception_exists?
        island_border_multiplier
      else
        mainland_border_multiplier
      end
    end

    def business_demand_curve
      @business_demand_curve ||= Calculation::DemandCurve.new(:business)
    end

    def demand_curve(type)
      if type == :business
        business_demand_curve
      elsif type == :leisure
        leisure_demand_curve
      end
    end

    def distance_demand(type)
      if origin_market.is_island && !island_exception_exists?
        demand_curve(type).relative_demand_island(flight_distance)
      else
        demand_curve(type).relative_demand(flight_distance)
      end
    end

    def island_border_multiplier
      if domestic?
        1
      elsif same_country_group?
        3/4.0
      else
        1/12.0
      end
    end

    def leisure_demand_curve
      @leisure_demand_curve ||= Calculation::DemandCurve.new(:leisure)
    end

    def mainland_border_multiplier
      if domestic?
        1
      elsif same_country_group?
        3/4.0
      else
        1/4.0
      end
    end

    def raw_demand(type)
      if origin_market == destination_market || RivalCountryGroup.rivals?(origin_market.country_group, destination_market.country_group)
        0
      else
        market_population / 100.0 * distance_demand(type) * border_multiplier * island_multipler
      end
    end
end
