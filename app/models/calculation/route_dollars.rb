class Calculation::RouteDollars
  def initialize(date, origin_airport, destination_airport)
    @date = date
    @origin_airport = origin_airport
    @destination_airport = destination_airport
  end

  def business
    directional_business_dollars(origin_global_demand, @destination_airport) +
      directional_business_dollars(destination_global_demand, @origin_airport)
  end

  def government
    directional_government_dollars(origin_global_demand, @destination_airport) +
      directional_government_dollars(destination_global_demand, @origin_airport)
  end

  def leisure
    directional_leisure_dollars(origin_global_demand, @destination_airport) +
      directional_leisure_dollars(destination_global_demand, @origin_airport)
  end

  def tourist
    directional_tourist_dollars(origin_global_demand, @destination_airport) +
      directional_tourist_dollars(destination_global_demand, @origin_airport)
  end

  private

    def directional_business_dollars(global_demand, destination)
      if global_demand.business == 0
        0
      else
        RouteDemand.calculate(@date, global_demand.airport, destination).business.to_f / global_demand.business * Calculation::MarketDollars.new(global_demand.airport, @date).business
      end
    end

    def directional_government_dollars(global_demand, destination)
      if global_demand.government == 0
        0
      else
        RouteDemand.calculate(@date, global_demand.airport, destination).government.to_f / global_demand.government * Calculation::MarketDollars.new(global_demand.airport, @date).government
      end
    end

    def directional_leisure_dollars(global_demand, destination)
      if global_demand.leisure == 0
        0
      else
        RouteDemand.calculate(@date, global_demand.airport, destination).leisure.to_f / global_demand.leisure * Calculation::MarketDollars.new(global_demand.airport, @date).leisure
      end
    end

    def directional_tourist_dollars(global_demand, destination)
      if global_demand.tourist == 0
        0
      else
        RouteDemand.calculate(@date, global_demand.airport, destination).tourist.to_f / global_demand.tourist * Calculation::MarketDollars.new(global_demand.airport, @date).tourist
      end
    end

    def origin_global_demand
      @origin_global_demand ||= GlobalDemand.calculate(@date, @origin_airport)
    end

    def destination_global_demand
      @destination_global_demand ||= GlobalDemand.calculate(@date, @destination_airport)
    end
end
