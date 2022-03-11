class AirlineRouteRevenue::Updater
  include Demandable

  def upsert(game)
    allocate_all(game).each do |airline_route, earned_revenue|
      arr = AirlineRouteRevenue.find_or_initialize_by(airline_route: airline_route)
      total_revenue = earned_revenue[:business] + earned_revenue[:premium_economy] + earned_revenue[:economy]
      # Round trip revenue count; one way passenger counts
      arr.assign_attributes(
        revenue: total_revenue.round(2),
        exclusive_economy_revenue: earned_revenue[:economy].round(2),
        exclusive_premium_economy_revenue: earned_revenue[:premium_economy].round(2),
        exclusive_business_revenue: earned_revenue[:business].round(2),
        economy_pax: (earned_revenue[:economy] / airline_route.economy_price.to_f / 2.0).round(7),
        premium_economy_pax: (earned_revenue[:premium_economy] / airline_route.premium_economy_price.to_f / 2.0).round(7),
        business_pax: (earned_revenue[:business] / airline_route.business_price.to_f / 2.0).round(7),
      )
      arr.save!
    end
  end

  private

    def allocate_all(game)
      economy = AirlineRouteRevenue::Allocator.allocate(solicited_economy_market_dollars_by_airline_flight(game), revenue_potential.max_economy_class_revenue_per_week)
      premium_economy = AirlineRouteRevenue::Allocator.allocate(solicited_premium_economy_market_dollars_by_airline_flight(game), revenue_potential.max_premium_economy_class_revenue_per_week)
      business = AirlineRouteRevenue::Allocator.allocate(solicited_business_market_dollars_by_airline_flight(game), revenue_potential.max_business_class_revenue_per_week)

      economy.select{ |ar, _| ar.airline.id.present? }.map do |airline_route, revenues|
        [airline_route, { :economy => revenues, :premium_economy => premium_economy[airline_route], :business => business[airline_route] }]
      end.to_h
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
