class Calculation::TotalMarketDemand
  def self.business(origin_airport, destination_market, date)
    self.total_demand(
      self.destination_business_demands(
        origin_airport,
        destination_market,
        date,
      ),
      destination_market,
    )
  end

  def self.government(origin_airport, destination_market, date)
    self.total_demand(
      self.destination_government_demands(
        origin_airport,
        destination_market,
        date,
      ),
      destination_market,
    )
  end

  def self.leisure(origin_airport, destination_market, date)
    self.total_demand(
      self.destination_leisure_demands(
        origin_airport,
        destination_market,
        date,
      ),
      destination_market,
    )
  end

  def self.tourist(origin_airport, destination_market, date)
    self.total_demand(
      self.destination_tourist_demands(
        origin_airport,
        destination_market,
        date,
      ),
      destination_market,
    )
  end

  private

    def self.destination_business_demands(origin_airport, destination_market, date)
      destination_market.airports.map { |airport|
        {
          airport: airport,
          demand: Calculation::ResidentDemand.new(origin_airport, airport).business_demand(date),
        }
      }
    end

    def self.destination_government_demands(origin_airport, destination_market, date)
      destination_market.airports.map { |airport|
        {
          airport: airport,
          demand: Calculation::GovernmentDemand.new(origin_airport, airport).demand(date),
        }
      }
    end

    def self.destination_leisure_demands(origin_airport, destination_market, date)
      destination_market.airports.map { |airport|
        {
          airport: airport,
          demand: Calculation::ResidentDemand.new(origin_airport, airport).leisure_demand(date),
        }
      }
    end

    def self.destination_tourist_demands(origin_airport, destination_market, date)
      destination_market.airports.map { |airport|
        {
          airport: airport,
          demand: Calculation::TouristDemand.new(origin_airport, airport).demand(date),
        }
      }
    end

    def self.exclusive_demands(destination_demands, destination_market)
      destination_demands.map { |demand|
        demand.fetch(:demand) * demand.fetch(:airport).exclusive_catchment.to_f / (destination_market.shared_catchment + demand.fetch(:airport).exclusive_catchment)
      }
    end

    def self.shared_demand(destination_demands, market)
      self.shared_demands(destination_demands, market).max
    end

    def self.shared_demands(destination_demands, market)
      destination_demands.map { |demand|
        demand.fetch(:demand) * market.shared_catchment.to_f / (market.shared_catchment + demand.fetch(:airport).exclusive_catchment)
      }
    end

    def self.total_demand(individual_demands, destination_market)
      self.shared_demand(individual_demands, destination_market) + self.exclusive_demands(individual_demands, destination_market).sum
    end
end
