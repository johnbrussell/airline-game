class MarketRevenue::Updater
  def initialize(market_1, market_2, game)
    @market_1 = market_1
    @market_2 = market_2
    @game = game
  end

  def update
    airline_routes.each do |airline_route|
      arr = AirlineRouteRevenue.find_or_initialize_by(airline_route: airline_route)

      economy_pax = passengers_economy(airline_route)
      premium_economy_pax = passengers_premium_economy(airline_route)
      business_pax = passengers_business(airline_route)

      # Round trip revenue count; one way passenger counts
      arr.assign_attributes(
        revenue: (airline_route.business_price * business_pax + airline_route.economy_price * economy_pax + airline_route.premium_economy_price * premium_economy_pax) * 2.0,
        exclusive_economy_revenue: 0,
        exclusive_premium_economy_revenue: 0,
        exclusive_business_revenue: 0,
        economy_pax: economy_pax,
        premium_economy_pax: premium_economy_pax,
        business_pax: business_pax,
      )
      arr.save!
    end
  end

  private

    def airline_routes
      @airline_routes ||= AirlineRoute.operators_in_market(@market_1, @market_2, @game)
    end

    def airplane_routes
      @airplane_routes = airline_routes.flat_map(&:airplane_routes)
    end

    def business_allocations
      @business_allocations ||= MarketRevenue::Allocator.new(initial_business_capacity, revenue_potentials_business).allocate_route_dollars
    end

    def economy_allocations
      @economy_allocations ||= MarketRevenue::Allocator.new(initial_economy_capacity, revenue_potentials_economy).allocate_route_dollars
    end

    def inertia_business_route_service
      route_dollars.map do |rd|
        inertia_service = Calculation::InertiaRouteService.new(rd.distance, rd.business, rd.economy, rd.premium_economy)
        MarketRevenue::RouteService.new(inertia_service.business_reputation_data, inertia_service.business_frequencies, inertia_service.business_seats_per_flight, rd.origin_airport_iata, rd.destination_airport_iata)
      end
    end

    def inertia_economy_route_service
      route_dollars.map do |rd|
        inertia_service = Calculation::InertiaRouteService.new(rd.distance, rd.business, rd.economy, rd.premium_economy)
        MarketRevenue::RouteService.new(inertia_service.economy_reputation_data, inertia_service.economy_frequencies, inertia_service.economy_seats_per_flight, rd.origin_airport_iata, rd.destination_airport_iata)
      end
    end

    def inertia_premium_economy_route_service
      route_dollars.map do |rd|
        inertia_service = Calculation::InertiaRouteService.new(rd.distance, rd.business, rd.economy, rd.premium_economy)
        MarketRevenue::RouteService.new(inertia_service.premium_economy_reputation_data, inertia_service.premium_economy_frequencies, inertia_service.premium_economy_seats_per_flight, rd.origin_airport_iata, rd.destination_airport_iata)
      end
    end

    def initial_business_capacity
      [
        airplane_routes.map { |ar| MarketRevenue::Capacity.new(ar, ar.business_reputation_data, ar.frequencies * ar.business_seats, ar.origin_airport_iata, ar.destination_airport_iata, nil, nil) },
        inertia_business_route_service.map { |ibrs| MarketRevenue::Capacity.new(nil, ibrs.reputation_data, ibrs.frequencies * ibrs.seats_per_flight, ibrs.origin_iata, ibrs.destination_iata, nil, nil) }
      ].flatten.select { |capacity| capacity.available_seats > 0 }
    end

    def initial_economy_capacity
      [
        airplane_routes.map { |ar| MarketRevenue::Capacity.new(ar, ar.economy_reputation_data, ar.frequencies * ar.economy_seats, ar.origin_airport_iata, ar.destination_airport_iata, nil, nil) },
        inertia_economy_route_service.map { |iers| MarketRevenue::Capacity.new(nil, iers.reputation_data, iers.frequencies * iers.seats_per_flight, iers.origin_iata, iers.destination_iata, nil, nil) }
      ].flatten.select { |capacity| capacity.available_seats > 0 }
    end

    def initial_premium_economy_capacity
      [
        airplane_routes.map { |ar| MarketRevenue::Capacity.new(ar, ar.premium_economy_reputation_data, ar.frequencies * ar.premium_economy_seats, ar.origin_airport_iata, ar.destination_airport_iata, nil, nil) },
        inertia_premium_economy_route_service.map { |ipers| MarketRevenue::Capacity.new(nil, ipers.reputation_data, ipers.frequencies * ipers.seats_per_flight, ipers.origin_iata, ipers.destination_iata, nil, nil) }
      ].flatten.select { |capacity| capacity.available_seats > 0 }
    end

    def passengers_business(airline_route)
      airline_route.total_business_seats - business_allocations.select { |allocation| allocation&.airplane_route&.route == airline_route}.sum(&:available_seats).to_f
    end

    def passengers_economy(airline_route)
      airline_route.total_economy_seats - economy_allocations.select { |allocation| allocation&.airplane_route&.route == airline_route}.sum(&:available_seats).to_f
    end

    def passengers_premium_economy(airline_route)
      airline_route.total_premium_economy_seats - premium_economy_allocations.select { |allocation| allocation&.airplane_route&.route == airline_route}.sum(&:available_seats).to_f
    end

    def premium_economy_allocations
      @premium_economy_allocations ||= MarketRevenue::Allocator.new(initial_premium_economy_capacity, revenue_potentials_premium_economy).allocate_route_dollars
    end

    def revenue_potentials_business
      route_dollars.map do |rd|
        # divide by 2 because total revenue is round trip
        MarketRevenue::RevenuePotential.new(rd.business / 2.0, rd.origin_airport_iata, rd.destination_airport_iata)
      end
    end

    def revenue_potentials_economy
      route_dollars.map do |rd|
        # divide by 2 because total revenue is round trip
        MarketRevenue::RevenuePotential.new(rd.economy / 2.0, rd.origin_airport_iata, rd.destination_airport_iata)
      end
    end

    def revenue_potentials_premium_economy
      route_dollars.map do |rd|
        # divide by 2 because total revenue is round trip
        MarketRevenue::RevenuePotential.new(rd.premium_economy / 2.0, rd.origin_airport_iata, rd.destination_airport_iata)
      end
    end

    def route_dollars
      @route_dollars ||= RouteDollars.between_markets(@market_1, @market_2, @game.current_date).sort_by { |rd| [rd.origin_airport_iata, rd.destination_airport_iata] }.reverse
    end
end
