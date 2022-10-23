class Calculation::RelativeDemand
  def initialize(date, origin_airport, destination_airport, origin_market, destination_market)
    @date = date
    @origin_airport = origin_airport
    @destination_airport = destination_airport
    @origin_market = origin_market
    @destination_market = destination_market
  end

  def business
    relative_demands[:business] * exclusivity_percentage
  end

  def government
    relative_demands[:government] * exclusivity_percentage
  end

  def leisure
    relative_demands[:leisure] * exclusivity_percentage
  end

  def tourist
    relative_demands[:tourist] * exclusivity_percentage
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

    def relative_demands
      @relative_demands ||= {
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
      }.tap do |t|
        destination_airports_with_demand.each do |destination|
          if destination&.exclusive_catchment > 0
            destination_airport_population = destination ? AirportPopulation.calculate(destination, @date) : nil
            origin_airports_with_demand.each do |origin|
              if origin&.exclusive_catchment > 0
                t[:business] += Calculation::ResidentDemand.new(origin, destination, @date, destination_airport_population).business_demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
                t[:government] += Calculation::GovernmentDemand.new(origin, destination, @date, destination_airport_population).demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
                t[:leisure] += Calculation::ResidentDemand.new(origin, destination, @date, destination_airport_population).leisure_demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
                t[:tourist] += Calculation::TouristDemand.new(origin, destination, @date, destination_airport_population).demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
              end
            end
          end
        end
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
