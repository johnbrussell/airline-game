class Calculation::TotalGlobalDemand
  def self.calculate(date, origin_airport)
    global_demand = GlobalDemand.find_by(market_id: origin_airport.market.id, date: date)
    if global_demand.nil?
      GlobalDemand.create!(
        market_id: origin_airport.market.id,
        date: date,
        business: market_business_demands(origin_airport, date).sum,
        government: market_government_demands(origin_airport, date).sum,
        leisure: market_leisure_demands(origin_airport, date).sum,
        tourist: market_tourist_demands(origin_airport, date).sum,
      )
    else
      global_demand
    end
  end

  private

    def self.market_business_demands(origin_airport, date)
      Market.all.map do |market|
        Calculation::TotalMarketDemand.business(origin_airport, market, date)
      end
    end

    def self.market_government_demands(origin_airport, date)
      Market.all.map do |market|
        Calculation::TotalMarketDemand.government(origin_airport, market, date)
      end
    end

    def self.market_leisure_demands(origin_airport, date)
      Market.all.map do |market|
        Calculation::TotalMarketDemand.leisure(origin_airport, market, date)
      end
    end

    def self.market_tourist_demands(origin_airport, date)
      Market.all.map do |market|
        Calculation::TotalMarketDemand.tourist(origin_airport, market, date)
      end
    end
end
