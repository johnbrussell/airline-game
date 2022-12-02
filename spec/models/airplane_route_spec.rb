require "rails_helper"

RSpec.describe AirplaneRoute do
  before(:each) do
    base = Fabricate(:market, name: "Default")
    Fabricate(:airline, base_id: base.id)
  end

  context "on_route" do
    it "finds all AirplaneRoutes on a route in a game" do
      game = Game.last
      other_game = Fabricate(:game)
      airline_1 = Airline.last
      airline_2 = Fabricate(:airline, game_id: game.id, base_id: airline_1.base_id)
      airline_3 = Fabricate(:airline, game_id: other_game.id, base_id: airline_1.base_id)
      origin = Fabricate(:airport, iata: "FUN", market: airline_1.base)
      destination = Fabricate(:airport, iata: "INU", market: airline_1.base)
      other_destination = Fabricate(:airport, iata: "MAJ", market: airline_1.base)
      airline_route_1 = AirlineRoute.create!(airline: airline_1, economy_price: 1, premium_economy_price: 1, business_price: 1, origin_airport: origin, destination_airport: destination)
      airline_route_2 = AirlineRoute.create!(airline: airline_2, economy_price: 1, premium_economy_price: 1, business_price: 1, origin_airport: origin, destination_airport: destination)
      airline_route_3 = AirlineRoute.create!(airline: airline_2, economy_price: 1, premium_economy_price: 1, business_price: 1, origin_airport: origin, destination_airport: other_destination)
      airline_route_4 = AirlineRoute.create!(airline: airline_3, economy_price: 1, premium_economy_price: 1, business_price: 1, origin_airport: origin, destination_airport: destination)

      family = Fabricate(:aircraft_family)
      airplane_1 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_1)
      airplane_2 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_1)
      airplane_3 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_2)
      airplane_4 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_3)

      AirplaneRoute.new(route: airline_route_1, airplane: airplane_1, flight_cost: 1, block_time_mins: 4, frequencies: 2).save(validate: false)
      airplane_route_1 = AirplaneRoute.last
      AirplaneRoute.new(route: airline_route_1, airplane: airplane_2, flight_cost: 1, block_time_mins: 4, frequencies: 2).save(validate: false)
      airplane_route_2 = AirplaneRoute.last
      AirplaneRoute.new(route: airline_route_2, airplane: airplane_3, flight_cost: 1, block_time_mins: 4, frequencies: 2).save(validate: false)
      airplane_route_3 = AirplaneRoute.last
      AirplaneRoute.new(route: airline_route_3, airplane: airplane_3, flight_cost: 1, block_time_mins: 4, frequencies: 2).save(validate: false)
      airplane_route_4 = AirplaneRoute.last
      AirplaneRoute.new(route: airline_route_4, airplane: airplane_4, flight_cost: 1, block_time_mins: 4, frequencies: 2).save(validate: false)
      airplane_route_5 = AirplaneRoute.last

      expect(AirplaneRoute.on_route(origin, destination, game)).to eq [airplane_route_1, airplane_route_2, airplane_route_3]
    end
  end

  context "airplane_built" do
    it "is true if the airplane is built" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airplane.update(construction_date: airplane.game.current_date)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be true
    end

    it "is false if the airplane is not built" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airplane.update(construction_date: airplane.game.current_date + 1.day)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Airplane cannot fly before it is built"
    end
  end

  context "airplane_can_fly_route" do
    it "is true when the airplane can fly the route" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be true
    end

    it "is false when the airplane cannot fly the route" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9996, elevation: 0, market: market)
      airport_3 = Fabricate(:airport, iata: "TRW", latitude: 10, longitude: 12, runway: 11000, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, economy_seats: 1, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_3.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      gates_3 = Gates.create!(airport: airport_3, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_3, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be true
      subject.save

      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Airplane cannot fly this route"
    end
  end

  context "airplane_operated_by_airline" do
    it "is true when the airline matches the operator of the airplane" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be true
    end

    it "is false when the airline and the airplane operator do not match" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      other_airline = Fabricate(:airline)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: other_airline, base_country_group: other_airline.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Operator of airplane does not match airline_route"
    end
  end

  context "airplane_time_is_logical" do
    it "is true when the time is calculated correctly" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", market: market)
      airport_2 = Fabricate(:airport, iata: "INU", market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 100, max_range: 13000, speed: 1000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = (3 * airplane.round_trip_block_time(airline_route.distance)).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 3)

      expect(subject.valid?).to be true
    end

    it "is false when the time is calculated incorrectly" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", market: market)
      airport_2 = Fabricate(:airport, iata: "INU", market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      airplane = Fabricate(:airplane, aircraft_family: family, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: 1, flight_cost: 1, frequencies: 3)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include("Block time mins is not correct")
    end
  end

  context "airplane_time_is_possible" do
    it "is correct if the route is the only route for the airplane" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      ).save(validate: false)
      subject = AirplaneRoute.last

      subject.validate
      expect(subject.errors.full_messages).not_to include "Airplane has too much block_time"

      expect(subject.update(block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS + 1)).to be false
      expect(subject.errors.full_messages).to include "Airplane has too much block time"
    end

    it "is correct if the airplane has other routes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      other_route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: other_route,
      ).save(validate: false)
      subject_1 = AirplaneRoute.last
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: trw,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      ).save(validate: false)
      subject_2 = AirplaneRoute.last
      subject_1.reload
      subject_2.reload

      subject_1.validate
      subject_2.validate
      expect(subject.errors.full_messages).not_to include "Airplane has too much block_time"
      expect(subject.errors.full_messages).not_to include "Airplane has too much block_time"

      expect(subject_1.update(block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2 + 2)).to be false
      expect(subject_1.errors.full_messages).to include "Airplane has too much block time"
      expect(subject_2.update(block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2 + 2)).to be false
      expect(subject_2.errors.full_messages).to include "Airplane has too much block time"
    end
  end

  context "daily_profit" do
    it "is calculated correctly" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, family: family, speed: 10000, max_range: 13000, takeoff_distance: 100, floor_space: 1000000)
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, economy_seats: 100, business_seats: 10, premium_economy_seats: 20, base_country_group: airline.base.country_group)
      other_airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, economy_seats: 100, business_seats: 10, premium_economy_seats: 20, base_country_group: airline.base.country_group)
      airline_route = AirlineRoute.create!(airline: airline, origin_airport: fun, destination_airport: inu, economy_price: 1, business_price: 2, premium_economy_price: 1.5)
      AirplaneRoute.new(airplane: other_airplane, route: airline_route, frequencies: 1, flight_cost: 150, block_time_mins: 1).save(validate: false)
      other_airplane_route = AirplaneRoute.last
      AirplaneRoute.new(airplane: airplane, route: airline_route, frequencies: 1, flight_cost: 300, block_time_mins: 1).save(validate: false)
      revenue = AirlineRouteRevenue.create!(business_pax: 20, premium_economy_pax: 40, economy_pax: 200, revenue: 600, exclusive_economy_revenue: 123.44, exclusive_business_revenue: 124.44, exclusive_premium_economy_revenue: 111.11, airline_route_id: airline_route.id)
      subject = AirplaneRoute.last

      expect(subject.daily_profit).to eq 0

      other_airplane_route.reload
      expect(other_airplane_route.daily_profit).to eq 150 / 7.0
    end

    it "can handle classes without service" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, family: family, speed: 10000, max_range: 13000, takeoff_distance: 100, floor_space: 1000000)
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, economy_seats: 100, business_seats: 0, premium_economy_seats: 20, base_country_group: airline.base.country_group)
      other_airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, economy_seats: 100, business_seats: 0, premium_economy_seats: 20, base_country_group: airline.base.country_group)
      airline_route = AirlineRoute.create!(airline: airline, origin_airport: fun, destination_airport: inu, economy_price: 1, business_price: 2, premium_economy_price: 1.5)
      AirplaneRoute.new(airplane: other_airplane, route: airline_route, frequencies: 1, flight_cost: 200, block_time_mins: 1).save(validate: false)
      other_airplane_route = AirplaneRoute.last
      AirplaneRoute.new(airplane: airplane, route: airline_route, frequencies: 1, flight_cost: 300, block_time_mins: 1).save(validate: false)
      revenue = AirlineRouteRevenue.create!(business_pax: 0, premium_economy_pax: 40, economy_pax: 200, revenue: 520, exclusive_economy_revenue: 1, exclusive_premium_economy_revenue: 1, exclusive_business_revenue: 1, airline_route_id: airline_route.id)
      subject = AirplaneRoute.last

      expect(subject.daily_profit).to eq -40 / 7.0

      other_airplane_route.reload
      expect(other_airplane_route.daily_profit).to eq 60 / 7.0
    end
  end

  context "destination_market_airport_iata" do
    let(:other_market) { Fabricate(:market, name: "Alphabetically first") }
    let(:destination_airport) { Airport.new(iata: "DEF", market: Market.find_by(name: "Default")) }
    let(:origin_airport) { Airport.new(iata: "ABC", market: other_market) }

    it "uses the destination_airport_iata when the markets are alphabetized" do
      airline_route = AirlineRoute.new(origin_airport: origin_airport, destination_airport: destination_airport)
      subject = AirplaneRoute.new(route: airline_route)

      expect(subject.destination_market_airport_iata).to eq "DEF"
    end

    it "uses the origin_airport_iata when the markets are not alphabetized" do
      airline_route = AirlineRoute.new(origin_airport: destination_airport, destination_airport: origin_airport)
      subject = AirplaneRoute.new(route: airline_route)

      expect(subject.destination_market_airport_iata).to eq "DEF"
    end
  end

  context "origin_market_airport_iata" do
    let(:other_market) { Fabricate(:market, name: "Alphabetically first") }
    let(:destination_airport) { Airport.new(iata: "DEF", market: Market.find_by(name: "Default")) }
    let(:origin_airport) { Airport.new(iata: "ABC", market: other_market) }

    it "uses the origin_airport_iata when the markets are alphabetized" do
      airline_route = AirlineRoute.new(origin_airport: origin_airport, destination_airport: destination_airport)
      subject = AirplaneRoute.new(route: airline_route)

      expect(subject.origin_market_airport_iata).to eq "ABC"
    end

    it "uses the destination_airport_iata when the markets are not alphabetized" do
      airline_route = AirlineRoute.new(origin_airport: destination_airport, destination_airport: origin_airport)
      subject = AirplaneRoute.new(route: airline_route)

      expect(subject.origin_market_airport_iata).to eq "ABC"
    end
  end

  context "recalculate_profits_and_block_time" do
    it "updates the block time, flight cost, and route revenue" do
      inu_market = Market.find_by(name: "Default")
      inu_market.update(name: "Nauru", income: 10000, country: "Nauru", country_group: "Nauru")
      inu_population = Population.create!(year: 2000, population: 10000, market_id: inu_market.id)
      inu_tourists = Tourists.create!(year: 2000, volume: 1000, market_id: inu_market.id)
      fun_market = Fabricate(:market, name: "Funafuti", income: 10000, country: "Tuvalu", country_group: "Tuvalu")
      fun_population = Population.create!(year: 2000, population: 10000, market_id: fun_market.id)
      fun_tourists = Tourists.create!(year: 2000, volume: 1000, market_id: fun_market.id)
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: fun_market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: inu_market)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1, speed: 1000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last, service_quality: 4)
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: 1, flight_cost: 1, frequencies: 1)
      subject.save(validate: false)
      flight_cost_calculator = instance_double(Calculation::FlightCostCalculator, cost: 100.40)
      allow(Calculation::FlightCostCalculator).to receive(:new).and_return(flight_cost_calculator)
      route_dollars = instance_double(RouteDollars, origin_market: fun_market, destination_market: inu_market, origin_airport_iata: "FUN", destination_airport_iata: "INU", date: Date.today, distance: 1000, business: 100, economy: 100, premium_economy: 100)
      allow(RouteDollars).to receive(:calculate).with(Date.today, fun_market, inu_market, nil, nil).and_return(route_dollars)
      allow(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, Date.today).and_return([route_dollars])
      airline_route.reload

      expect(AirlineRouteRevenue.count).to eq 0

      expect(subject.recalculate_profits_and_block_time).to be true
      subject.reload

      expect(AirlineRouteRevenue.count).to eq 1
      revenue = AirlineRouteRevenue.last
      expect(revenue.revenue).to eq 2
      expect(revenue.business_pax).to eq 0
      expect(revenue.premium_economy_pax).to eq 0
      expect(revenue.economy_pax).to eq 1

      expect(subject.block_time_mins).to be > 1
      expect(subject.frequencies).to eq 1
      expect(subject.flight_cost).to eq 200.80
    end
  end

  context "routes_connected" do
    it "is true if the airplane has no other routes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      gates_inu = Gates.create!(airport: inu, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_inu, lessee_id: Airline.last.id)
      gates_fun = Gates.create!(airport: fun, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      subject = AirplaneRoute.new(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )

      expect(subject.valid?).to be true
    end

    it "is true if the airplane flies an adjacent route" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      gates_inu = Gates.create!(airport: inu, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_inu, lessee_id: Airline.last.id)
      gates_fun = Gates.create!(airport: fun, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      gates_trw = Gates.create!(airport: trw, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_trw, lessee_id: Airline.last.id)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.create!(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )
      airplane.reload
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: trw,
        airline: Airline.last,
      )
      subject = AirplaneRoute.new(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )

      expect(subject.valid?).to be true
    end

    it "is false if the airplane flies routes but no adjacent route" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)
      gates_inu = Gates.create!(airport: inu, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_inu, lessee_id: Airline.last.id)
      gates_fun = Gates.create!(airport: fun, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      gates_trw = Gates.create!(airport: trw, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_trw, lessee_id: Airline.last.id)
      gates_maj = Gates.create!(airport: maj, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_maj, lessee_id: Airline.last.id)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.create!(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )
      airplane.reload
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: maj,
        destination_airport: trw,
        airline: Airline.last,
      )
      subject = AirplaneRoute.new(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Route does not connect to airplane's route network"
    end
  end

  context "set_frequency" do
    it "updates the frequency when the airplane can add the requested service" do
      inu_market = Market.find_by(name: "Default")
      inu_market.update(name: "Nauru", income: 10000, country: "Nauru", country_group: "Nauru")
      inu_population = Population.create!(year: 2000, population: 10000, market_id: inu_market.id)
      inu_tourists = Tourists.create!(year: 2000, volume: 1000, market_id: inu_market.id)
      fun_market = Fabricate(:market, name: "Funafuti", income: 10000, country: "Tuvalu", country_group: "Tuvalu")
      fun_population = Population.create!(year: 2000, population: 10000, market_id: fun_market.id)
      fun_tourists = Tourists.create!(year: 2000, volume: 1000, market_id: fun_market.id)
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: fun_market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: inu_market)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1, speed: 1000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last, service_quality: 4)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane)
      flight_cost_calculator = instance_double(Calculation::FlightCostCalculator, cost: 100.40)
      allow(Calculation::FlightCostCalculator).to receive(:new).and_return(flight_cost_calculator)
      route_dollars = instance_double(RouteDollars, origin_market: fun_market, destination_market: inu_market, origin_airport_iata: "FUN", destination_airport_iata: "INU", date: Date.today, distance: 1000, business: 100, economy: 100, premium_economy: 100)
      allow(RouteDollars).to receive(:calculate).with(Date.today, fun_market, inu_market, nil, nil).and_return(route_dollars)
      allow(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, Date.today).and_return([route_dollars])
      airline_route.reload

      airplane_route_count = AirplaneRoute.count

      expect(AirlineRouteRevenue.count).to eq 0

      expect(subject.new_record?).to be true
      subject.set_frequency(1)
      expect(AirplaneRoute.count).to eq airplane_route_count + 1

      expect(AirlineRouteRevenue.count).to eq 1
      revenue = AirlineRouteRevenue.last
      expect(revenue.revenue).to eq 2
      expect(revenue.business_pax).to eq 0
      expect(revenue.premium_economy_pax).to eq 0
      expect(revenue.economy_pax).to eq 1

      subject.reload

      expect(subject.new_record?).to be false
      expect(subject.block_time_mins).to eq block_time
      expect(subject.frequencies).to eq 1
      expect(subject.flight_cost).to eq 200.80

      subject.set_frequency(0)
      expect(AirplaneRoute.count).to eq airplane_route_count

      expect(AirlineRouteRevenue.count).to eq 1
      revenue = AirlineRouteRevenue.last
      expect(revenue.revenue).to eq 0
      expect(revenue.business_pax).to eq 0
      expect(revenue.premium_economy_pax).to eq 0
      expect(revenue.economy_pax).to eq 0
    end

    it "does not update the frequency when the airplane cannot add the requested service" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane)

      airplane_route_count = AirplaneRoute.count

      expect(subject.new_record?).to be true

      subject.set_frequency(10000)

      expect(AirplaneRoute.count).to eq airplane_route_count
      expect(subject.new_record?).to be true
      expect(AirlineRouteRevenue.count).to eq 0
    end
  end

  context "slots_sufficient" do
    it "is true when there are enough slots at the origin and destination to open the route" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be true
    end

    it "is false when there are not enough slots at the origin" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include("Slots not leased in sufficient quantity")
    end

    it "is false when there are not enough slots at the destination" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include("Slots not leased in sufficient quantity")
    end

    it "is false when there are too many other flights at the origin or destination" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      airport_3 = Fabricate(:airport, iata: "WLS", latitude: 12, longitude: 12, runway: 10000, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: 1000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route_1 = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      airline_route_2 = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_3.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route_1.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      gates_3 = Gates.create!(airport: airport_3, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_3, lessee_id: Airline.last.id)
      AirplaneRoute.create!(route: airline_route_1, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)
      subject = AirplaneRoute.new(route: airline_route_2, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1)

      expect(subject.send(:slots_used_at_origin)).to eq 1

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include("Slots not leased in sufficient quantity")
    end
  end

  context "update_costs" do
    it "calculates correctly" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: 1000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      block_time = airplane.round_trip_block_time(airline_route.distance).round
      gates_1 = Gates.create!(airport: airport_1, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_1, lessee_id: Airline.last.id)
      gates_2 = Gates.create!(airport: airport_2, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_2, lessee_id: Airline.last.id)
      AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: block_time, flight_cost: 1, frequencies: 1).save(validate: false)
      subject = AirplaneRoute.last

      expect(subject.update_costs).to be true
      expect(subject.flight_cost).to be > 1
    end
  end

  context "validate_remaining_routes_connected" do
    it "is true if the airplane has no other routes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      gates_inu = Gates.create!(airport: inu, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_inu, lessee_id: Airline.last.id)
      gates_fun = Gates.create!(airport: fun, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      subject = AirplaneRoute.create(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )

      expect(AirplaneRoute.count).to eq 1
      subject.destroy
      expect(AirplaneRoute.count).to eq 0
    end

    it "is true if the airplane's network remains intact" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      gates_inu = Gates.create!(airport: inu, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_inu, lessee_id: Airline.last.id)
      gates_fun = Gates.create!(airport: fun, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      gates_trw = Gates.create!(airport: trw, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_trw, lessee_id: Airline.last.id)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.create!(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: trw,
        airline: Airline.last,
      )
      subject = AirplaneRoute.create(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )

      expect(AirplaneRoute.count).to eq 2
      subject.destroy
      expect(AirplaneRoute.count).to eq 1
    end

    it "is false if the airplane's network would be split" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      gates_inu = Gates.create!(airport: inu, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_inu, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_inu, lessee_id: Airline.last.id)
      gates_fun = Gates.create!(airport: fun, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      gates_trw = Gates.create!(airport: trw, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_trw, lessee_id: Airline.last.id)
      gates_maj = Gates.create!(airport: maj, game: airplane.game, current_gates: 100)
      Slot.create!(gates: gates_maj, lessee_id: Airline.last.id)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      subject = AirplaneRoute.create(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: trw,
        airline: Airline.last,
      )
      AirplaneRoute.create!(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: inu,
        destination_airport: maj,
        airline: Airline.last,
      )
      AirplaneRoute.create!(
        block_time_mins: airplane.round_trip_block_time(route.distance).round,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )
      subject.reload

      expect(AirplaneRoute.count).to eq 3
      subject.destroy
      expect(AirplaneRoute.count).to eq 3
      expect(subject.errors.full_messages).to include "Route is necessary to keep airplane's routes connected"
    end
  end
end
