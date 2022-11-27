class Calculation::RouteDollars
  def initialize(date, origin_market, destination_market, origin_airport, destination_airport)
    @date = date
    @origin_market = origin_market
    @destination_market = destination_market
    @origin_airport = origin_airport
    @destination_airport = destination_airport
  end

  def business_class_dollars
    business_dollars * class_calculator.pct_business_dollars_business + leisure_dollars * class_calculator.pct_leisure_dollars_business
  end

  def distance
    relative_demand.distance
  end

  def economy_class_dollars
    business_dollars * class_calculator.pct_business_dollars_economy + leisure_dollars * class_calculator.pct_leisure_dollars_economy
  end

  def premium_economy_class_dollars
    business_dollars * class_calculator.pct_business_dollars_premium_economy + leisure_dollars * class_calculator.pct_leisure_dollars_premium_economy
  end

  private

    def business_dollars
      business_dollars_from_business + business_dollars_from_government
    end

    def business_dollars_from_business
      if total_market_demand.business == 0
        0
      else
        market_dollars.business * relative_demand.business / total_market_demand.business.to_f
      end
    end

    def business_dollars_from_government
      if total_market_demand.government == 0
        0
      else
        market_dollars.government * relative_demand.government / total_market_demand.government.to_f
      end
    end

    def class_calculator
      @class_calculator ||= Calculation::ClassOfService.new(relative_demand.distance)
    end

    def leisure_dollars
      leisure_dollars_from_leisure + leisure_dollars_from_tourist
    end

    def leisure_dollars_from_leisure
      if total_market_demand.leisure == 0
        0
      else
        market_dollars.leisure * relative_demand.leisure / total_market_demand.leisure.to_f
      end
    end

    def leisure_dollars_from_tourist
      if total_market_demand.tourist == 0
        0
      else
        market_dollars.tourist * relative_demand.tourist / total_market_demand.tourist.to_f
      end
    end

    def market_dollars
      @market_dollars ||= MarketDollars.calculate(@origin_market, @date)
    end

    def relative_demand
      @relative_demand ||= RelativeDemand.most_recent_or_initialize(@date, @origin_airport, @destination_airport, @origin_market, @destination_market)
    end

    def total_market_demand
      @total_market_demand ||= TotalMarketDemand.calculate(@origin_market, @date)
    end
end
