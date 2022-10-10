class Calculation::RelativeDemand
  def initialize(date, origin_airport, destination_airport)
    @date = date
    @origin_airport = origin_airport
    @destination_airport = destination_airport
  end

  def calculate
    RelativeDemand.create!(
      origin_market_id: @origin_airport.market.id,
      destination_market_id: @destination_airport.market.id,
      origin_airport_iata: @origin_airport.iata,
      destination_airport_iata: @destination_airport.iata,
      business: relative_business_demand * exclusivity_percentage,
      government: relative_government_demand * exclusivity_percentage,
      leisure: relative_leisure_demand * exclusivity_percentage,
      tourist: relative_tourist_demand * exclusivity_percentage,
      pct_business: pct_business,
      pct_economy: pct_economy,
      pct_premium_economy: pct_premium_economy,
      last_measured: @date,
    )
  end

  private

    def airports_with_demand(airport)
      if airport.iata.present?
        [airport]
      else
        airport.market.airports.to_a
      end
    end

    def destination_airports_with_demand
      @destination_airports_with_demand ||= airports_with_demand(@destination_airport)
    end

    def exclusive_catchment(airport)
      if airport.iata.present?
        airport.exclusive_catchment / 100.0
      else
        airport.market.shared_catchment / 100.0
      end
    end

    def exclusivity_percentage
      exclusive_catchment(@origin_airport) * exclusive_catchment(@destination_airport)
    end

    def pct_business
      1 / 3.0
    end

    def pct_economy
      1 / 3.0
    end

    def pct_premium_economy
      1 / 3.0
    end

    def origin_airports_with_demand
      @origin_airports_with_demand ||= airports_with_demand(@origin_airport)
    end

    def relative_business_demand
      origin_airports_with_demand.product(destination_airports_with_demand).sum do |origin, destination|
        Calculation::ResidentDemand.new(origin, destination, @date).business_demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
      end
    end

    def relative_government_demand
      origin_airports_with_demand.product(destination_airports_with_demand).sum do |origin, destination|
        Calculation::GovernmentDemand.new(origin, destination, @date).demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
      end
    end

    def relative_leisure_demand
      origin_airports_with_demand.product(destination_airports_with_demand).sum do |origin, destination|
        Calculation::ResidentDemand.new(origin, destination, @date).leisure_demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
      end
    end

    def relative_tourist_demand
      origin_airports_with_demand.product(destination_airports_with_demand).sum do |origin, destination|
        Calculation::TouristDemand.new(origin, destination, @date).demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
      end
    end
end
