class Calculation::RouteDollars
  def initialize(date, origin_airport, destination_airport)
    @date = date
    @origin_airport = origin_airport
    @destination_airport = destination_airport
  end

  def business
    directional_business_dollars(origin_global_demand, destination_route_demand) +
      directional_business_dollars(destination_global_demand, origin_route_demand)
  end

  def exclusive_business
    directional_exclusive_business_dollars(origin_global_demand, destination_route_demand) +
      directional_exclusive_business_dollars(destination_global_demand, origin_route_demand)
  end

  def exclusive_government
    directional_exclusive_government_dollars(origin_global_demand, destination_route_demand) +
      directional_exclusive_government_dollars(destination_global_demand, origin_route_demand)
  end

  def exclusive_leisure
    directional_exclusive_leisure_dollars(origin_global_demand, destination_route_demand) +
      directional_exclusive_leisure_dollars(destination_global_demand, origin_route_demand)
  end

  def exclusive_tourist
    directional_exclusive_tourist_dollars(origin_global_demand, destination_route_demand) +
      directional_exclusive_tourist_dollars(destination_global_demand, origin_route_demand)
  end

  def government
    directional_government_dollars(origin_global_demand, destination_route_demand) +
      directional_government_dollars(destination_global_demand, origin_route_demand)
  end

  def leisure
    directional_leisure_dollars(origin_global_demand, destination_route_demand) +
      directional_leisure_dollars(destination_global_demand, origin_route_demand)
  end

  def tourist
    directional_tourist_dollars(origin_global_demand, destination_route_demand) +
      directional_tourist_dollars(destination_global_demand, origin_route_demand)
  end

  private

    def directional_business_dollars(global_demand, route_demand)
      if global_demand.business == 0
        0
      else
        route_demand.business.to_f / global_demand.business * Calculation::MarketDollars.new(global_demand.airport, @date).business
      end
    end

    def directional_exclusive_business_dollars(global_demand, route_demand)
      if global_demand.business == 0
        0
      else
        route_demand.exclusive_business.to_f / global_demand.business * Calculation::MarketDollars.new(global_demand.airport, @date).business
      end
    end

    def directional_exclusive_government_dollars(global_demand, route_demand)
      if global_demand.government == 0
        0
      else
        route_demand.exclusive_government.to_f / global_demand.government * Calculation::MarketDollars.new(global_demand.airport, @date).government
      end
    end

    def directional_exclusive_leisure_dollars(global_demand, route_demand)
      if global_demand.leisure == 0
        0
      else
        route_demand.exclusive_leisure.to_f / global_demand.leisure * Calculation::MarketDollars.new(global_demand.airport, @date).leisure
      end
    end

    def directional_exclusive_tourist_dollars(global_demand, route_demand)
      if global_demand.tourist == 0
        0
      else
        route_demand.exclusive_tourist.to_f / global_demand.tourist * Calculation::MarketDollars.new(global_demand.airport, @date).tourist
      end
    end

    def directional_government_dollars(global_demand, route_demand)
      if global_demand.government == 0
        0
      else
        route_demand.government.to_f / global_demand.government * Calculation::MarketDollars.new(global_demand.airport, @date).government
      end
    end

    def directional_leisure_dollars(global_demand, route_demand)
      if global_demand.leisure == 0
        0
      else
        route_demand.leisure.to_f / global_demand.leisure * Calculation::MarketDollars.new(global_demand.airport, @date).leisure
      end
    end

    def directional_tourist_dollars(global_demand, route_demand)
      if global_demand.tourist == 0
        0
      else
        route_demand.tourist.to_f / global_demand.tourist * Calculation::MarketDollars.new(global_demand.airport, @date).tourist
      end
    end

    def origin_global_demand
      @origin_global_demand ||= GlobalDemand.calculate(@date, @origin_airport)
    end

    def origin_route_demand
      @origin_route_demand ||= RouteDemand.calculate(@date, @destination_airport, @origin_airport)
    end

    def destination_global_demand
      @destination_global_demand ||= GlobalDemand.calculate(@date, @destination_airport)
    end

    def destination_route_demand
      @destination_route_demand ||= RouteDemand.calculate(@date, @origin_airport, @destination_airport)
    end
end
