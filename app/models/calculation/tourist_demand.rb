class Calculation::TouristDemand
  include Populatable

  def demand
    if origin_market == destination_market || RivalCountryGroup.rivals?(origin_market.country_group, destination_market.country_group)
      0
    else
      airport_population / 100.0 * distance_demand * border_multiplier
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
      if origin_market.is_island  && !IslandException.excepted?(origin_market, destination_market)
        demand_curve.relative_demand_island(distance)
      else
        demand_curve.relative_demand(distance)
      end
    end
end
