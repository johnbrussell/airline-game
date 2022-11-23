class MarketRevenue::Allocator
  def initialize(capacity_to_allocate, route_dollars_to_allocate)
    @capacity_to_allocate = capacity_to_allocate
    @route_dollars_to_allocate = route_dollars_to_allocate
  end

  def allocate_route_dollars
    remaining_capacity = @capacity_to_allocate
    @route_dollars_to_allocate.each do |rd|
      remaining_capacity = identify_capacity_utilized(rd, remaining_capacity)
    end
    remaining_capacity
  end

  private

    def compatible_flight?(revenue_potential, flight_capacity)
      compatible_iatas?(revenue_potential.origin_iata, flight_capacity.origin_iata) &&
        compatible_iatas?(revenue_potential.destination_iata, flight_capacity.destination_iata)
    end

    def compatible_iatas?(revenue_iata, flight_iata)
      revenue_iata == flight_iata || revenue_iata.empty?
    end

    def identify_capacity_utilized(revenue_potential, flight_capacities)
      full_flights = flight_capacities.select { |fc| fc.available_seats == 0 }
      invalid_flights = flight_capacities.reject { |fc| fc.available_seats == 0 || compatible_flight?(revenue_potential, fc) }
      flights_with_seats = flight_capacities.reject { |fc| fc.available_seats == 0}.select { |fc| compatible_flight?(revenue_potential, fc) }
      remaining_dollars = revenue_potential.dollars

      while remaining_dollars > 0 && flights_with_seats.any?
        all_reputation_data = flights_with_seats.map(&:reputation_data)
        flights_with_seats.each { |fws| fws.reputation = Calculation::RouteReputation.new(fws.reputation_data, all_reputation_data).reputation.to_f }
        total_reputation = flights_with_seats.sum { |fws| fws.reputation * fws.reputation_data.frequencies }

        flights_with_seats.each { |fws| fws.dollars_to_fill = (fws.available_seats * fws.reputation_data.fare) / (fws.reputation_data.frequencies * fws.reputation / total_reputation) }

        next_dollar_exhaustion = [flights_with_seats.min_by(&:dollars_to_fill).dollars_to_fill, remaining_dollars].min

        flights_with_seats.each do |fws|
          if fws.dollars_to_fill == next_dollar_exhaustion
            fws.available_seats = 0
          else
            fws.available_seats = fws.available_seats * (1 - next_dollar_exhaustion / fws.dollars_to_fill)
          end
        end

        full_flights = full_flights + flights_with_seats.select { |fws| fws.available_seats == 0 }
        flights_with_seats = flights_with_seats.reject { |fws| fws.available_seats == 0 }
        remaining_dollars = remaining_dollars == next_dollar_exhaustion ? 0 : remaining_dollars - next_dollar_exhaustion
      end

      [full_flights, flights_with_seats, invalid_flights].flatten
    end
end
