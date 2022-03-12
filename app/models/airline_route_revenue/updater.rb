class AirlineRouteRevenue::Updater
  include Demandable

  def upsert(game)
    allocate_all(game).each do |airline_route, earned_revenue|
      arr = AirlineRouteRevenue.find_or_initialize_by(airline_route: airline_route)

      exclusive_economy_revenue = earned_revenue.fetch(:exclusive_economy, arr.exclusive_economy_revenue)
      exclusive_premium_economy_revenue = earned_revenue.fetch(:exclusive_premium_economy, arr.exclusive_premium_economy_revenue)
      exclusive_business_revenue = earned_revenue.fetch(:exclusive_business, arr.exclusive_business_revenue)
      shared_economy_revenue = earned_revenue.fetch(:shared_economy, 0) * airline_route.relative_demand_to(@origin, @destination, :economy)
      shared_premium_economy_revenue = earned_revenue.fetch(:shared_premium_economy, 0) * airline_route.relative_demand_to(@origin, @destination, :premium_economy)
      shared_business_revenue = earned_revenue.fetch(:shared_business, 0) * airline_route.relative_demand_to(@origin, @destination, :business)
      total_revenue = exclusive_economy_revenue +
        exclusive_premium_economy_revenue +
        exclusive_business_revenue +
        shared_economy_revenue +
        shared_premium_economy_revenue +
        shared_business_revenue
      total_economy_revenue = exclusive_economy_revenue + shared_economy_revenue
      total_premium_economy_revenue = exclusive_premium_economy_revenue + shared_premium_economy_revenue
      total_business_revenue = exclusive_business_revenue + shared_business_revenue

      # Round trip revenue count; one way passenger counts
      arr.assign_attributes(
        revenue: total_revenue.round(2),
        exclusive_economy_revenue: exclusive_economy_revenue.round(2),
        exclusive_premium_economy_revenue: exclusive_premium_economy_revenue.round(2),
        exclusive_business_revenue: exclusive_business_revenue.round(2),
        economy_pax: (total_economy_revenue / airline_route.economy_price.to_f / 2.0).round(7),
        premium_economy_pax: (total_premium_economy_revenue / airline_route.premium_economy_price.to_f / 2.0).round(7),
        business_pax: (total_business_revenue / airline_route.business_price.to_f / 2.0).round(7),
      )
      arr.save!
    end
  end

  private

    def allocate_all(game)
      exclusive_economy_revenue, remaining_economy_solicitations = AirlineRouteRevenue::Allocator.allocate_and_subtract_solicitations(
        solicited_economy_market_dollars_by_airline_flight(game),
        revenue_potential.max_exclusive_economy_class_revenue_per_week,
      )
      exclusive_economy_revenue = exclusive_economy_revenue.map { |ar, r| [ar, { :exclusive_economy => r }] }.to_h
      exclusive_premium_economy_revenue, remaining_premium_economy_solicitations = AirlineRouteRevenue::Allocator.allocate_and_subtract_solicitations(
        solicited_premium_economy_market_dollars_by_airline_flight(game),
        revenue_potential.max_exclusive_premium_economy_class_revenue_per_week,
      )
      exclusive_premium_economy_revenue = exclusive_premium_economy_revenue.map { |ar, r| [ar, { :exclusive_premium_economy => r }] }.to_h
      exclusive_business_revenue, remaining_business_solicitations = AirlineRouteRevenue::Allocator.allocate_and_subtract_solicitations(
        solicited_business_market_dollars_by_airline_flight(game),
        revenue_potential.max_exclusive_business_class_revenue_per_week,
      )
      exclusive_business_revenue = exclusive_business_revenue.map { |ar, r| [ar, { :exclusive_business => r }] }.to_h

      shared_economy_solicitations = other_shared_solicited_economy_market_dollars(game).merge(remaining_economy_solicitations)
      remaining_economy_revenue = revenue_potential.max_economy_class_revenue_per_week - revenue_potential.max_exclusive_economy_class_revenue_per_week
      shared_premium_economy_solicitations = other_shared_solicited_premium_economy_market_dollars(game).merge(remaining_premium_economy_solicitations)
      remaining_premium_economy_revenue = revenue_potential.max_premium_economy_class_revenue_per_week - revenue_potential.max_exclusive_premium_economy_class_revenue_per_week
      shared_business_solicitations = other_shared_solicited_business_market_dollars(game).merge(remaining_business_solicitations)
      remaining_business_revenue = revenue_potential.max_business_class_revenue_per_week - revenue_potential.max_exclusive_business_class_revenue_per_week

      shared_economy_revenue = AirlineRouteRevenue::Allocator.allocate(shared_economy_solicitations, remaining_economy_revenue)
      shared_economy_revenue = shared_economy_revenue.map { |ar, r| [ar, { :shared_economy => r }] }.to_h
      shared_premium_economy_revenue = AirlineRouteRevenue::Allocator.allocate(shared_premium_economy_solicitations, remaining_premium_economy_revenue)
      shared_premium_economy_revenue = shared_premium_economy_revenue.map { |ar, r| [ar, { :shared_premium_economy => r }] }.to_h
      shared_business_revenue = AirlineRouteRevenue::Allocator.allocate(shared_business_solicitations, remaining_business_revenue)
      shared_business_revenue = shared_business_revenue.map { |ar, r| [ar, { :shared_business => r }] }.to_h

      exclusive_economy_revenue.merge(exclusive_premium_economy_revenue, exclusive_business_revenue, shared_economy_revenue, shared_premium_economy_revenue, shared_business_revenue) { |key, hash1, hash2| hash1.merge(hash2) }.select { |ar, _| ar.airline_id.present? }
    end

    def inertia_airline_route(frequencies, game)
      AirlineRoute.new(
        airline: Airline.new(game_id: game.id),
        origin_airport: @origin,
        destination_airport: @destination,
        business_price: inertia_calculator.business_fare,
        economy_price: inertia_calculator.economy_fare,
        premium_economy_price: inertia_calculator.premium_economy_fare,
        airplane_routes: [
          AirplaneRoute.new(
            frequencies: frequencies,
            airplane: Airplane.new(
              business_seats: inertia_calculator.business_seats_per_flight,
              economy_seats: inertia_calculator.economy_seats_per_flight,
              premium_economy_seats: inertia_calculator.premium_economy_seats_per_flight,
              aircraft_model: AircraftModel.new(
                floor_space: inertia_calculator.business_seats_per_flight * Airplane::BUSINESS_SEAT_SIZE \
                  + inertia_calculator.premium_economy_seats_per_flight * Airplane::PREMIUM_ECONOMY_SEAT_SIZE \
                  + inertia_calculator.economy_seats_per_flight * Airplane::ECONOMY_SEAT_SIZE,
              ),
            ),
          ),
        ],
      )
    end

    def inertia_airline_route_business(game)
      inertia_airline_route(inertia_calculator.business_frequencies, game)
    end

    def inertia_airline_route_economy(game)
      inertia_airline_route(inertia_calculator.economy_frequencies, game)
    end

    def inertia_airline_route_premium_economy(game)
      inertia_airline_route(inertia_calculator.premium_economy_frequencies, game)
    end

    def inertia_calculator
      @inertia_calculator ||= Calculation::InertiaRouteService.new(@origin, @destination, @current_date)
    end

    def operators_of_other_market_routes(game)
      @operators_of_other_market_routes ||= AirlineRoute.operators_of_other_market_routes(@origin, @destination, game)
    end

    def other_shared_solicited_business_market_dollars(game)
      other_solicited_business_market_dollars(game).map do |airline_route, flights|
        [
          airline_route,
          AirlineRouteRevenue::Allocator.subtract_exclusive_allocations( { airline_route => flights }, airline_route.revenue.exclusive_business_revenue).fetch(airline_route, [0]).map do |amt|
            amt / airline_route.relative_demand_to(@origin, @destination, :business)
          end,
        ]
      end.to_h
    end

    def other_shared_solicited_economy_market_dollars(game)
      other_solicited_economy_market_dollars(game).map do |airline_route, flights|
        [
          airline_route,
          AirlineRouteRevenue::Allocator.subtract_exclusive_allocations( { airline_route => flights }, airline_route.revenue.exclusive_economy_revenue).fetch(airline_route, [0]).map do |amt|
            amt / airline_route.relative_demand_to(@origin, @destination, :economy)
          end,
        ]
      end.to_h
    end

    def other_shared_solicited_premium_economy_market_dollars(game)
      other_solicited_premium_economy_market_dollars(game).map do |airline_route, flights|
        [
          airline_route,
          AirlineRouteRevenue::Allocator.subtract_exclusive_allocations( { airline_route => flights }, airline_route.revenue.exclusive_premium_economy_revenue).fetch(airline_route, [0]).map do |amt|
            amt / airline_route.relative_demand_to(@origin, @destination, :premium_economy)
          end,
        ]
      end.to_h
    end

    def other_solicited_business_market_dollars(game)
      operators_of_other_market_routes(game).map do |airline_route|
        [
          airline_route, airline_route.airplane_routes.flat_map { |ar| [ar.airplane.business_seats * airline_route.business_price * 2] * ar.frequencies }
        ]
      end.to_h
    end

    def other_solicited_economy_market_dollars(game)
      operators_of_other_market_routes(game).map do |airline_route|
        [
          airline_route, airline_route.airplane_routes.flat_map { |ar| [ar.airplane.economy_seats * airline_route.economy_price * 2] * ar.frequencies }
        ]
      end.to_h
    end

    def other_solicited_premium_economy_market_dollars(game)
      operators_of_other_market_routes(game).map do |airline_route|
        [
          airline_route, airline_route.airplane_routes.flat_map { |ar| [ar.airplane.premium_economy_seats * airline_route.premium_economy_price * 2] * ar.frequencies }
        ]
      end.to_h
    end

    def relevant_airline_routes(game)
      @relevant_airline_routes ||= AirlineRoute.operators_of_route(@origin, @destination, game)
    end

    def relevant_airline_routes_business(game)
      if inertia_calculator.business_frequencies > 0
        relevant_airline_routes(game) + [inertia_airline_route_business(game)]
      else
        relevant_airline_routes(game)
      end
    end

    def relevant_airline_routes_economy(game)
      relevant_airline_routes(game) + [inertia_airline_route_economy(game)]
    end

    def relevant_airline_routes_premium_economy(game)
      relevant_airline_routes(game) + [inertia_airline_route_premium_economy(game)]
    end

    def revenue_potential
      @revenue_potential ||= Calculation::MaximumRevenuePotential.new(@origin, @destination, @current_date)
    end

    def solicited_business_market_dollars_by_airline_flight(game)
      relevant_airline_routes_business(game).map do |airline_route|
        [
          airline_route, airline_route.airplane_routes.flat_map { |ar| [ar.airplane.business_seats * airline_route.business_price * 2.0] * ar.frequencies }
        ]
      end.to_h
    end

    def solicited_economy_market_dollars_by_airline_flight(game)
      relevant_airline_routes_economy(game).map do |airline_route|
        [
          airline_route, airline_route.airplane_routes.flat_map { |ar| [ar.airplane.economy_seats * airline_route.economy_price * 2.0] * ar.frequencies }
        ]
      end.to_h
    end

    def solicited_premium_economy_market_dollars_by_airline_flight(game)
      relevant_airline_routes_premium_economy(game).map do |airline_route|
        [
          airline_route, airline_route.airplane_routes.flat_map { |ar| [ar.airplane.premium_economy_seats * airline_route.premium_economy_price * 2.0] * ar.frequencies }
        ]
      end.to_h
    end
end
