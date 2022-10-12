class Calculation::RelativeDemand
  def initialize(date, origin_airport, destination_airport, origin_market, destination_market)
    @date = date
    @origin_airport = origin_airport
    @destination_airport = destination_airport
    @origin_market = origin_market
    @destination_market = destination_market
  end

  def calculate
    RelativeDemand.find_or_initialize_by(
      origin_market_id: @origin_market.id,
      destination_market_id: @destination_market.id,
      origin_airport_iata: origin_airport_iata,
      destination_airport_iata: destination_airport_iata,
      last_measured: @date,
    ).tap do |relative_demand|
      relative_demand.assign_attributes(
        business: relative_business_demand * exclusivity_percentage,
        government: relative_government_demand * exclusivity_percentage,
        leisure: relative_leisure_demand * exclusivity_percentage,
        tourist: relative_tourist_demand * exclusivity_percentage,
        pct_business: 1 / 3.0,
        pct_economy: 1 / 3.0,
        pct_premium_economy: 1 / 3.0,
      )
      relative_demand.save!
    end
  end

  private

    def destination_airport_iata
      @destination_airport ? @destination_airport.iata : ""
    end

    def destination_airports_with_demand
      @destination_airports_with_demand ||= if @destination_airport.present?
          [@destination_airport]
        else
          @destination_market.airports.to_a
        end
    end

    def destination_exclusive_catchment
      if @destination_airport.present?
        @destination_airport.exclusive_catchment / 100.0
      else
        @destination_market.shared_catchment / 100.0
      end
    end

    def exclusivity_percentage
      origin_exclusive_catchment * destination_exclusive_catchment
    end

    def origin_airport_iata
      @origin_airport ? @origin_airport.iata : ""
    end

    def origin_airports_with_demand
      @origin_airports_with_demand ||= if @origin_airport.present?
          [@origin_airport]
        else
          @origin_market.airports.to_a
        end
    end

    def origin_exclusive_catchment
      if @origin_airport.present?
        @origin_airport.exclusive_catchment / 100.0
      else
        @origin_market.shared_catchment / 100.0
      end
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
