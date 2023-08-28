class Calculation::RelativeDemand
  def initialize(date, origin_airport, destination_airport, origin_market, destination_market)
    @date = date
    @origin_airport = origin_airport
    @destination_airport = destination_airport
    @origin_market = origin_market
    @destination_market = destination_market
  end

  def business
    relative_business_demand * exclusivity_percentage
  end

  def distance
    relative_demands[:distance]
  end

  def government
    relative_government_demand * exclusivity_percentage
  end

  def leisure
    relative_leisure_demand * exclusivity_percentage
  end

  def tourist
    relative_tourist_demand * exclusivity_percentage
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
        distance: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
      }.tap do |t|
        destination_airports_with_demand.each do |destination|
          if destination&.exclusive_catchment > 0
            origin_airports_with_demand.each do |origin|
              if origin&.exclusive_catchment > 0
                resident_demand_calculator = Calculation::ResidentDemand.new(origin, destination, @date)
                t[:business] += resident_demand_calculator.business_demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
                t[:distance] += Calculation::Distance.between_airports(origin, destination) * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
                t[:government] += Calculation::GovernmentDemand.new(origin, destination, @date).demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
                t[:leisure] += resident_demand_calculator.leisure_demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
                t[:tourist] += Calculation::TouristDemand.new(origin, destination, @date).demand * origin.exclusive_catchment / origin_airports_with_demand.sum(&:exclusive_catchment) * destination.exclusive_catchment / destination_airports_with_demand.sum(&:exclusive_catchment)
              end
            end
          end
        end
      end
    end

    def relative_business_demand
      relative_demands[:business]
    end

    def relative_government_demand
      relative_demands[:government]
    end

    def relative_leisure_demand
      relative_demands[:leisure]
    end

    def relative_tourist_demand
      relative_demands[:tourist]
    end
end
