require "rails_helper"

RSpec.describe MarketRevenue::Updater do
  let(:game) { Fabricate(:game) }
  let(:fun_market) { Fabricate(:market, name: "Funafuti", country_group: "Pacific") }
  let(:inu_market) { Fabricate(:market, name: "Nauru", country_group: "Pacific") }
  let(:airline) { Fabricate(:airline, game_id: game.id, base_id: inu_market.id) }
  let(:other_airline) { Fabricate(:airline, game_id: game.id, base_id: airline.base_id) }
  let(:origin_airport) { Fabricate(:airport, iata: "FUN", market: fun_market) }
  let(:other_origin_airport) { Fabricate(:airport, iata: "NFU", market: fun_market) }
  let(:destination_airport) { Fabricate(:airport, iata: "INU", market: inu_market) }
  let(:other_destination_airport) { Fabricate(:airport, iata: "NRU", market: inu_market) }
  let(:family) { Fabricate(:aircraft_family) }

  context "update" do
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: business_seats * business_fare * frequencies * 2,
          economy: economy_seats * economy_fare * frequencies * 2,
          premium_economy: premium_economy_seats * premium_economy_fare * frequencies * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      expect(result.economy_pax).to eq economy_seats * frequencies / 2.0
      expect(result.premium_economy_pax).to eq premium_economy_seats * frequencies / 2.0
      expect(result.business_pax).to eq business_seats * frequencies / 2.0
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: business_seats * business_fare * frequencies * 2,
          economy: economy_seats * economy_fare * frequencies * 2,
          premium_economy: premium_economy_seats * premium_economy_fare * frequencies * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      expect(result.economy_pax).to eq economy_seats * frequencies / 2.0
      expect(result.premium_economy_pax).to eq premium_economy_seats * frequencies / 2.0
      expect(result.business_pax).to eq business_seats * frequencies / 2.0
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: business_seats * business_fare * frequencies * 2,
          economy: economy_seats * economy_fare * frequencies * 2,
          premium_economy: premium_economy_seats * premium_economy_fare * frequencies * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      reputation_difference = AirlineRoute::MAX_REPUTATION - AirlineRoute::MIN_REPUTATION
      adjusted_reputation_difference = AirlineRoute::REPUTATION_WEIGHTS[:ifs] * reputation_difference

      expect(result.revenue).to be > (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      assert_in_delta result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * (1 + adjusted_reputation_difference / (2 + adjusted_reputation_difference)), 0.005
      expect(result.economy_pax).to be > economy_seats * frequencies / 2.0
      assert_in_delta result.economy_pax, economy_seats * frequencies * (1 + adjusted_reputation_difference / (2 + adjusted_reputation_difference)) / 2.0, 0.005
      expect(result.premium_economy_pax).to be > premium_economy_seats * frequencies / 2.0
      assert_in_delta result.premium_economy_pax, premium_economy_seats * frequencies * (1 + adjusted_reputation_difference / (2 + adjusted_reputation_difference)) / 2.0, 0.005
      expect(result.business_pax).to be > business_seats * frequencies / 2.0
      assert_in_delta result.business_pax, business_seats * frequencies * (1 + adjusted_reputation_difference / (2 + adjusted_reputation_difference)) / 2.0, 0.005
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: business_seats * business_fare * frequencies * 2,
          economy: economy_seats * economy_fare * frequencies * 2,
          premium_economy: premium_economy_seats * premium_economy_fare * frequencies * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, exclusive_economy_revenue: 1000, exclusive_business_revenue: 1, exclusive_premium_economy_revenue: 1, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).save(validate: false)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 1

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies
      expect(result.economy_pax).to eq economy_seats * frequencies / 2.0
      expect(result.premium_economy_pax).to eq premium_economy_seats * frequencies / 2.0
      expect(result.business_pax).to eq business_seats * frequencies / 2.0
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: business_seats * business_fare * frequencies * 2 * 2,
          economy: economy_seats * economy_fare * frequencies * 2 * 2,
          premium_economy: premium_economy_seats * premium_economy_fare * frequencies * 2 * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, exclusive_business_revenue: 1000, exclusive_premium_economy_revenue: 1, exclusive_economy_revenue: 1, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).save(validate: false)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 1

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: 100 * business_seats * business_fare * frequencies * 2,
          economy: economy_seats * economy_fare * frequencies * 2 * 2,
          premium_economy: premium_economy_seats * premium_economy_fare * frequencies * 2 * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, exclusive_economy_revenue: 1000, exclusive_premium_economy_revenue: 1, exclusive_business_revenue: 1, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).save(validate: false)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 1

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2.0
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: business_seats * business_fare * frequencies * 2 * 2,
          economy: 1000 * economy_seats * economy_fare * frequencies * 2,
          premium_economy: 200 * premium_economy_seats * premium_economy_fare * frequencies * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, exclusive_economy_revenue: 1000, exclusive_premium_economy_revenue: 1, exclusive_business_revenue: 1, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).save(validate: false)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 1

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      expect(result.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2.0
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: business_seats * business_fare * frequencies * 2,
          economy: economy_seats * economy_fare * frequencies * 2,
          premium_economy: premium_economy_seats * premium_economy_fare * frequencies * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 2

      result = AirlineRouteRevenue.first

      assert_in_epsilon result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 / 3.0, 0.00000001
      assert_in_epsilon result.economy_pax, economy_seats * frequencies * 2 / 3.0 / 2.0, 0.0000001
      assert_in_epsilon result.premium_economy_pax, premium_economy_seats * frequencies * 2 / 3.0 / 2.0, 0.0000001
      assert_in_epsilon result.business_pax, business_seats * frequencies * 2 / 3.0 / 2.0, 0.0000001

      result = AirlineRouteRevenue.last

      assert_in_epsilon result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 / 3.0, 0.00000001
      assert_in_epsilon result.economy_pax, economy_seats * frequencies * 2 / 3.0 / 2.0, 0.0000001
      assert_in_epsilon result.premium_economy_pax, premium_economy_seats * frequencies * 2 / 3.0 / 2.0, 0.0000001
      assert_in_epsilon result.business_pax, business_seats * frequencies * 2 / 3.0 / 2.0, 0.0000001
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: business_seats * business_fare * frequencies * 2,
          economy: economy_seats * economy_fare * frequencies * 2,
          premium_economy: premium_economy_seats * premium_economy_fare * frequencies * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      reputation_difference = AirlineRoute::MAX_REPUTATION - AirlineRoute::MIN_REPUTATION

      assert_in_epsilon result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 * 2 / 3.0 * (1 + reputation_difference * 0.3 / (245 * 3).to_f), 0.00001
      assert_in_epsilon result.economy_pax, economy_seats * frequencies * 2 * 2 / 3.0 * (1 + reputation_difference * 0.3 / (245 * 3).to_f) / 2.0, 0.00001
      assert_in_epsilon result.premium_economy_pax, premium_economy_seats * frequencies * 2 * 2 / 3.0 * (1 + reputation_difference * 0.3 / (245 * 3).to_f) / 2.0, 0.00001
      assert_in_epsilon result.business_pax, business_seats * frequencies * 2 * 2 / 3.0 * (1 + reputation_difference * 0.3 / (245 * 3).to_f) / 2.0, 0.00001
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
        business_reputation_data: Calculation::ReputationData.new(nil, business_fare, frequencies, 1, 0),
        economy_seats_per_flight: economy_seats,
        economy_fare: economy_fare,
        economy_frequencies: frequencies,
        economy_reputation_data: Calculation::ReputationData.new(nil, economy_fare, frequencies, 1, 0),
        premium_economy_seats_per_flight: premium_economy_seats,
        premium_economy_fare: premium_economy_fare,
        premium_economy_frequencies: frequencies,
        premium_economy_reputation_data: Calculation::ReputationData.new(nil, premium_economy_fare, frequencies, 1, 0),
      )
      allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: business_seats * business_fare * frequencies * 2,
          economy: economy_seats * economy_fare * frequencies * 2,
          premium_economy: premium_economy_seats * premium_economy_fare * frequencies * 2,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 0

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq 1

      result = AirlineRouteRevenue.last

      reputation_difference = AirlineRoute::MAX_REPUTATION - AirlineRoute::MIN_REPUTATION

      assert_in_epsilon result.revenue, (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 * 2 / 3.0 * (1 + reputation_difference * 0.3 / (245 * 3).to_f), 0.00001
      assert_in_epsilon result.economy_pax, economy_seats * frequencies * 2 * 2 / 3.0 * (1 + reputation_difference * 0.3 / (245 * 3).to_f) / 2.0, 0.00001
      assert_in_epsilon result.premium_economy_pax, premium_economy_seats * frequencies * 2 * 2 / 3.0 * (1 + reputation_difference * 0.3 / (245 * 3).to_f) / 2.0, 0.00001
      assert_in_epsilon result.business_pax, business_seats * frequencies * 2 * 2 / 3.0 * (1 + reputation_difference * 0.3 / (245 * 3).to_f) / 2.0, 0.00001
      expect(result.airline_route_id).to eq airline_route.id
    end

    it "adjusts other routes in the market when they exist" do
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
      other_airline = Fabricate(:airline, base_id: fun_market.id, game_id: game.id)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)
      airplane_route = AirplaneRoute.last
      airline_route.reload

      other_airline_route = AirlineRoute.create!(
        airline: other_airline,
        origin_airport: other_origin_airport,
        destination_airport: other_destination_airport,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      other_airplane_route = AirplaneRoute.new(
        route: other_airline_route,
        airplane: other_airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)
      other_airline_route_revenue = AirlineRouteRevenue.create!(
        airline_route: other_airline_route,
        revenue: 30000,
        exclusive_economy_revenue: 10000,
        exclusive_premium_economy_revenue: 10000,
        exclusive_business_revenue: 10000,
        economy_pax: economy_seats / 2.0,
        premium_economy_pax: premium_economy_seats / 2.0,
        business_pax: business_seats / 2.0,
      )

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: 100000,
          economy: 1000000,
          premium_economy: 1000000,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).twice.with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      airline_route_revenue = AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, exclusive_economy_revenue: 1000, exclusive_business_revenue: 1, exclusive_premium_economy_revenue: 1, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).tap do |arr|
        arr.save(validate: false)
      end
      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 2

      inu_market.reload
      fun_market.reload
      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq original_record_count

      airline_route_revenue.reload
      other_airline_route_revenue.reload

      expect(airline_route_revenue.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2
      expect(airline_route_revenue.economy_pax).to eq economy_seats * frequencies
      expect(airline_route_revenue.premium_economy_pax).to eq premium_economy_seats * frequencies
      expect(airline_route_revenue.business_pax).to eq business_seats * frequencies
      expect(airline_route_revenue.valid?).to be true

      expect(other_airline_route_revenue.revenue).to eq airline_route_revenue.revenue
      expect(other_airline_route_revenue.valid?).to be true

      airplane_route.assign_attributes(frequencies: frequencies * 2)
      airplane_route.save!(validate: false)
      airline_route.reload

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      airline_route_revenue.reload
      other_airline_route_revenue.reload

      expect(other_airline_route_revenue.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2
      expect(airline_route_revenue.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 * 2
      expect(airline_route_revenue.valid?).to be true
      expect(other_airline_route_revenue.valid?).to be true
    end

    it "adjusts other routes in the market when they exist and the revenue does not fill all of the seats" do
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
      other_airline = Fabricate(:airline, base_id: fun_market.id, game_id: game.id)

      airline_route = AirlineRoute.create!(
        airline: airline,
        origin_airport: origin_airport,
        destination_airport: destination_airport,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      AirplaneRoute.new(
        route: airline_route,
        airplane: airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)
      airplane_route = AirplaneRoute.last
      airline_route.reload

      other_airline_route = AirlineRoute.create!(
        airline: other_airline,
        origin_airport: other_origin_airport,
        destination_airport: other_destination_airport,
        economy_price: economy_fare,
        premium_economy_price: premium_economy_fare,
        business_price: business_fare,
      )
      other_airplane_route = AirplaneRoute.new(
        route: other_airline_route,
        airplane: other_airplane,
        flight_cost: 1,
        frequencies: frequencies,
        block_time_mins: 1,
      ).save(validate: false)
      other_airline_route_revenue = AirlineRouteRevenue.create!(
        airline_route: other_airline_route,
        revenue: 30000,
        exclusive_economy_revenue: 10000,
        exclusive_premium_economy_revenue: 10000,
        exclusive_business_revenue: 10000,
        economy_pax: economy_seats / 2.0,
        premium_economy_pax: premium_economy_seats / 2.0,
        business_pax: business_seats / 2.0,
      )

      route_dollars = [
        instance_double(
          RouteDollars,
          distance: 100,
          business: 70000,
          economy: 201400,
          premium_economy: 200810,
          origin_airport_iata: "",
          destination_airport_iata: "",
        )
      ]
      expect(RouteDollars).to receive(:between_markets).twice.with(fun_market, inu_market, game.current_date).and_return(route_dollars)

      airline_route_revenue = AirlineRouteRevenue.new(airline_route_id: airline_route.id, revenue: 1000, exclusive_economy_revenue: 1000, exclusive_business_revenue: 1, exclusive_premium_economy_revenue: 1, economy_pax: 20, business_pax: 1, premium_economy_pax: 999).tap do |arr|
        arr.save(validate: false)
      end
      original_record_count = AirlineRouteRevenue.count
      expect(original_record_count).to eq 2

      inu_market.reload
      fun_market.reload
      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      expect(AirlineRouteRevenue.count).to eq original_record_count

      airline_route_revenue.reload
      other_airline_route_revenue.reload

      expect(airline_route_revenue.economy_pax).to eq economy_seats * frequencies
      expect(airline_route_revenue.premium_economy_pax).to eq premium_economy_seats * frequencies
      expect(airline_route_revenue.business_pax).to eq business_seats * frequencies
      expect(airline_route_revenue.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2
      expect(airline_route_revenue.valid?).to be true

      expect(other_airline_route_revenue.revenue).to eq airline_route_revenue.revenue
      expect(other_airline_route_revenue.economy_pax).to eq economy_seats * frequencies
      expect(other_airline_route_revenue.premium_economy_pax).to eq premium_economy_seats * frequencies
      expect(other_airline_route_revenue.business_pax).to eq business_seats * frequencies
      expect(other_airline_route_revenue.valid?).to be true

      airplane_route.assign_attributes(frequencies: frequencies * 2)
      airplane_route.save!(validate: false)
      airline_route.reload

      subject = MarketRevenue::Updater.new(fun_market, inu_market, game)
      subject.update

      airline_route_revenue.reload
      other_airline_route_revenue.reload

      expect(other_airline_route_revenue.revenue).to be < (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2
      expect(airline_route_revenue.revenue).to eq (business_seats * business_fare + premium_economy_seats * premium_economy_fare + economy_seats * economy_fare) * frequencies * 2 * 2
      expect(airline_route_revenue.valid?).to be true
      expect(other_airline_route_revenue.valid?).to be true
    end
  end
end
