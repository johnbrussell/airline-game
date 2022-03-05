require "rails_helper"

RSpec.describe Calculation::AirlineRouteRevenueUpdater do
  let(:game) { Fabricate(:game) }
  let(:market) { Fabricate(:market) }
  let(:airline) { Fabricate(:airline, game_id: game.id, base_id: market.id) }
  let(:other_airline) { Fabricate(:airline, game_id: game.id, base_id: airline.base_id) }
  let(:origin_airport) { Fabricate(:airport, iata: "FUN", market: market) }
  let(:destination_airport) { Fabricate(:airport, iata: "INU", market: market) }
  let(:family) { Fabricate(:aircraft_family) }

  context "upsert" do
    it "creates the right AirlineRouteRevenues when they are new" do
      economy_seats = 100
      premium_economy_seats = 20
      business_seats = 10
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats, business_seats: business_seats, premium_economy_seats: premium_economy_seats)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)

      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_seats * business_fare * frequencies * 2,
        max_economy_class_revenue_per_week: economy_seats * economy_fare * frequencies * 2,
        max_premium_economy_class_revenue_per_week: premium_economy_seats * premium_economy_fare * frequencies * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      expect(result.economy_pax).to eq economy_seats * frequencies
      expect(result.premium_economy_pax).to eq premium_economy_seats * frequencies
      expect(result.business_pax).to eq business_seats * frequencies
      expect(result.airline_route_id).to eq airline_route.id
    end

    it "works when the planes are not full" do
      economy_seats = 100
      premium_economy_seats = 20
      business_seats = 10
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = (Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats) * 2
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats * 2, business_seats: business_seats * 2, premium_economy_seats: premium_economy_seats * 2)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)

      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_seats * business_fare * frequencies * 2,
        max_economy_class_revenue_per_week: economy_seats * economy_fare * frequencies * 2,
        max_premium_economy_class_revenue_per_week: premium_economy_seats * premium_economy_fare * frequencies * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      expect(result.economy_pax).to eq economy_seats * frequencies
      expect(result.premium_economy_pax).to eq premium_economy_seats * frequencies
      expect(result.business_pax).to eq business_seats * frequencies
      expect(result.airline_route_id).to eq airline_route.id
    end

    it "splits proportionally to reputation" do
      economy_seats = 100
      premium_economy_seats = 20
      business_seats = 10
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = (Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats) * 2
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats * 2, business_seats: business_seats * 2, premium_economy_seats: premium_economy_seats * 2)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
        service_quality: 5,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)

      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_seats * business_fare * frequencies * 2,
        max_economy_class_revenue_per_week: economy_seats * economy_fare * frequencies * 2,
        max_premium_economy_class_revenue_per_week: premium_economy_seats * premium_economy_fare * frequencies * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      # 11 / 21.0 * 2 because service quality is 10% of possible reputation - ratio depends on AirlineRoute::REPUTATION_WEIGHTS
      expect(result.revenue).to be > (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      assert_in_delta result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 11 / 21.0 * 2, 0.005
      expect(result.economy_pax).to be > economy_seats * frequencies
      assert_in_delta result.economy_pax, economy_seats * frequencies * 11 / 21.0 * 2, 0.005
      expect(result.premium_economy_pax).to be > premium_economy_seats * frequencies
      assert_in_delta result.premium_economy_pax, premium_economy_seats * frequencies * 11 / 21.0 * 2, 0.005
      expect(result.business_pax).to be > business_seats * frequencies
      assert_in_delta result.business_pax, business_seats * frequencies * 11 / 21.0 * 2, 0.005
      expect(result.airline_route_id).to eq airline_route.id
    end

    it "updates the right AirlineRouteRevenues when they already exist" do
      economy_seats = 100
      premium_economy_seats = 20
      business_seats = 10
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats, business_seats: business_seats, premium_economy_seats: premium_economy_seats)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)

      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_seats * business_fare * frequencies * 2,
        max_economy_class_revenue_per_week: economy_seats * economy_fare * frequencies * 2,
        max_premium_economy_class_revenue_per_week: premium_economy_seats * premium_economy_fare * frequencies * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).save(validate: false)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 1

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      expect(result.economy_pax).to eq economy_seats * frequencies
      expect(result.premium_economy_pax).to eq premium_economy_seats * frequencies
      expect(result.business_pax).to eq business_seats * frequencies
      expect(result.airline_route_id).to eq airline_route.id
    end

    it "does not assign more revenue than is possible" do
      economy_seats = 100
      premium_economy_seats = 20
      business_seats = 10
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats, business_seats: business_seats, premium_economy_seats: premium_economy_seats)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)

      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_seats * business_fare * frequencies * 2 * 2,
        max_economy_class_revenue_per_week: economy_seats * economy_fare * frequencies * 2 * 2,
        max_premium_economy_class_revenue_per_week: premium_economy_seats * premium_economy_fare * frequencies * 2 * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).save(validate: false)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 1

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      expect(result.economy_pax).to eq economy_seats * frequencies
      expect(result.premium_economy_pax).to eq premium_economy_seats * frequencies
      expect(result.business_pax).to eq business_seats * frequencies
      expect(result.airline_route_id).to eq airline_route.id
    end

    it "works when there are no business seats in the market" do
      economy_seats = 100
      premium_economy_seats = 20
      business_seats = 0
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats, business_seats: business_seats, premium_economy_seats: premium_economy_seats)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)

      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: 100 * business_fare * 2,
        max_economy_class_revenue_per_week: economy_seats * economy_fare * frequencies * 2 * 2,
        max_premium_economy_class_revenue_per_week: premium_economy_seats * premium_economy_fare * frequencies * 2 * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).save(validate: false)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 1

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      expect(result.economy_pax).to eq economy_seats * frequencies
      expect(result.premium_economy_pax).to eq premium_economy_seats * frequencies
      expect(result.business_pax).to eq business_seats * frequencies
      expect(result.airline_route_id).to eq airline_route.id
    end

    it "works when there are no premium economy or economy seats in the market" do
      economy_seats = 0
      premium_economy_seats = 0
      business_seats = 10
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats, business_seats: business_seats, premium_economy_seats: premium_economy_seats)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)

      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_seats * business_fare * frequencies * 2 * 2,
        max_economy_class_revenue_per_week: 1000 * economy_fare * frequencies * 2,
        max_premium_economy_class_revenue_per_week: 200 * premium_economy_fare * frequencies * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).save(validate: false)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 1

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      expect(result.economy_pax).to eq economy_seats * frequencies
      expect(result.premium_economy_pax).to eq premium_economy_seats * frequencies
      expect(result.business_pax).to eq business_seats * frequencies
      expect(result.airline_route_id).to eq airline_route.id
    end

    it "can handle multiple airlines" do
      economy_seats = 100
      premium_economy_seats = 20
      business_seats = 10
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats, business_seats: business_seats, premium_economy_seats: premium_economy_seats)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)
      other_airline_route = AirlineRoute.create!(
        airline: other_airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      other_airplane_route = AirplaneRoute.new(
        route: other_airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)


      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_seats * business_fare * frequencies * 2,
        max_economy_class_revenue_per_week: economy_seats * economy_fare * frequencies * 2,
        max_premium_economy_class_revenue_per_week: premium_economy_seats * premium_economy_fare * frequencies * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 2

      result = AirlineRouteRevenue.first

      assert_in_epsilon result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 / 3.0, 0.00000001
      assert_in_epsilon result.economy_pax, economy_seats * frequencies * 2 / 3.0, 0.00000001
      assert_in_epsilon result.premium_economy_pax, premium_economy_seats * frequencies * 2 / 3.0, 0.00000001
      assert_in_epsilon result.business_pax, business_seats * frequencies * 2 / 3.0, 0.00000001

      result = AirlineRouteRevenue.last

      assert_in_epsilon result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 / 3.0, 0.00000001
      assert_in_epsilon result.economy_pax, economy_seats * frequencies * 2 / 3.0, 0.00000001
      assert_in_epsilon result.premium_economy_pax, premium_economy_seats * frequencies * 2 / 3.0, 0.00000001
      assert_in_epsilon result.business_pax, business_seats * frequencies * 2 / 3.0, 0.00000001
    end

    it "can handle multiple airplanes" do
      economy_seats = 100
      premium_economy_seats = 20
      business_seats = 10
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats, business_seats: business_seats, premium_economy_seats: premium_economy_seats)
      other_airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats, business_seats: business_seats, premium_economy_seats: premium_economy_seats)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)
      other_airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: other_airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)

      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_seats * business_fare * frequencies * 2,
        max_economy_class_revenue_per_week: economy_seats * economy_fare * frequencies * 2,
        max_premium_economy_class_revenue_per_week: premium_economy_seats * premium_economy_fare * frequencies * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      assert_in_epsilon result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 * 2 / 3.0 * (1 + 0.3 / (245 * 3).to_f), 0.00001
      assert_in_epsilon result.economy_pax, economy_seats * frequencies * 2 * 2 / 3.0 * (1 + 0.3 / (245 * 3).to_f), 0.00001
      assert_in_epsilon result.premium_economy_pax, premium_economy_seats * frequencies * 2 * 2 / 3.0 * (1 + 0.3 / (245 * 3).to_f), 0.00001
      assert_in_epsilon result.business_pax, business_seats * frequencies * 2 * 2 / 3.0 * (1 + 0.3 / (245 * 3).to_f), 0.00001
      expect(result.airline_route_id).to eq airline_route.id
    end

    it "can handle multiple frequencies" do
      economy_seats = 100
      premium_economy_seats = 20
      business_seats = 10
      economy_fare = 100
      premium_economy_fare = 500
      business_fare = 1000
      frequencies = 1
      floor_space = Airplane::ECONOMY_SEAT_SIZE * economy_seats + Airplane::PREMIUM_ECONOMY_SEAT_SIZE * premium_economy_seats + Airplane::BUSINESS_SEAT_SIZE * business_seats
      model = Fabricate(:aircraft_model, family: family, floor_space: floor_space)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: economy_seats, business_seats: business_seats, premium_economy_seats: premium_economy_seats)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        distance: 1,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      airplane_route = AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies * 2,
        block_time_mins: 1,
      ).save(validate: false)

      inertia_route_service = instance_double(
        Calculation::InertiaRouteService,
        business_seats_per_flight: business_seats,
        business_fare: business_fare,
        business_frequencies: frequencies,
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      maximum_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_seats * business_fare * frequencies * 2,
        max_economy_class_revenue_per_week: economy_seats * economy_fare * frequencies * 2,
        max_premium_economy_class_revenue_per_week: premium_economy_seats * premium_economy_fare * frequencies * 2,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(maximum_revenue)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = Calculation::AirlineRouteRevenueUpdater.new(origin_airport, destination_airport, Date.today)
      subject.upsert(game)

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      assert_in_epsilon result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 * 2 / 3.0 * (1 + 0.3 / (245 * 3).to_f), 0.00001
      assert_in_epsilon result.economy_pax, economy_seats * frequencies * 2 * 2 / 3.0 * (1 + 0.3 / (245 * 3).to_f), 0.00001
      assert_in_epsilon result.premium_economy_pax, premium_economy_seats * frequencies * 2 * 2 / 3.0 * (1 + 0.3 / (245 * 3).to_f), 0.00001
      assert_in_epsilon result.business_pax, business_seats * frequencies * 2 * 2 / 3.0 * (1 + 0.3 / (245 * 3).to_f), 0.00001
      expect(result.airline_route_id).to eq airline_route.id
    end
  end
end
