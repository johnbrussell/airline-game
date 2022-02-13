class Calculation::RouteDollars
  def initialize(date, origin_airport, destination_airport)
    @date = date
    @origin_airport = origin_airport
    @destination_airport = destination_airport
  end

  def business
    directional_business_dollars(@origin_airport, @destination_airport) +
      directional_business_dollars(@destination_airport, @origin_airport)
  end

  def government
    directional_government_dollars(@origin_airport, @destination_airport) +
      directional_government_dollars(@destination_airport, @origin_airport)
  end

  def leisure
    directional_leisure_dollars(@origin_airport, @destination_airport) +
      directional_leisure_dollars(@destination_airport, @origin_airport)
  end

  def tourist
    directional_tourist_dollars(@origin_airport, @destination_airport) +
      directional_tourist_dollars(@destination_airport, @origin_airport)
  end

  private

    def directional_business_dollars(origin, destination)
      if GlobalDemand.calculate(@date, origin).business == 0
        0
      else
        RouteDemand.calculate(@date, origin, destination).business.to_f / GlobalDemand.calculate(@date, origin).business * Calculation::MarketDollars.new(origin, @date).business
      end
    end

    def directional_government_dollars(origin, destination)
      if GlobalDemand.calculate(@date, origin).government == 0
        0
      else
        RouteDemand.calculate(@date, origin, destination).government.to_f / GlobalDemand.calculate(@date, origin).government * Calculation::MarketDollars.new(origin, @date).government
      end
    end

    def directional_leisure_dollars(origin, destination)
      if GlobalDemand.calculate(@date, origin).leisure == 0
        0
      else
        RouteDemand.calculate(@date, origin, destination).leisure.to_f / GlobalDemand.calculate(@date, origin).leisure * Calculation::MarketDollars.new(origin, @date).leisure
      end
    end

    def directional_tourist_dollars(origin, destination)
      if GlobalDemand.calculate(@date, origin).tourist == 0
        0
      else
        RouteDemand.calculate(@date, origin, destination).tourist.to_f / GlobalDemand.calculate(@date, origin).tourist * Calculation::MarketDollars.new(origin, @date).tourist
      end
    end
end
