require "rails_helper"

RSpec.describe AirlineRoute do
  context "operators_in_market" do
    it "includes only routes from airlines that operate in the market and sorts them" do
      game = Fabricate(:game)
      other_game = Fabricate(:game)

      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)

      airline_c = Fabricate(:airline, base_id: inu.market.id, name: "C", game_id: game.id)
      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A", game_id: game.id)
      airline_b = Fabricate(:airline, base_id: inu.market.id, name: "B", game_id: game.id)
      airline_d = Fabricate(:airline, base_id: inu.market.id, name: "D", game_id: game.id)
      other_airline = Fabricate(:airline, base_id: inu.market.id, game_id: game.id)
      other_game_airline = Fabricate(:airline, base_id: inu.market.id, game_id: other_game.id)
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000)
      airplane_c = Fabricate(:airplane, aircraft_family: family, operator_id: airline_c.id, base_country_group: airline_c.base.country_group, aircraft_model: super_model)
      airplane_a = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model)
      airplane_b = Fabricate(:airplane, aircraft_family: family, operator_id: airline_b.id, base_country_group: airline_b.base.country_group, aircraft_model: super_model)
      airplane_d = Fabricate(:airplane, aircraft_family: family, operator_id: airline_d.id, base_country_group: airline_d.base.country_group, aircraft_model: super_model)
      airplane_other_game = Fabricate(:airplane, aircraft_family: family, operator_id: other_game_airline.id, base_country_group: other_game_airline.base.country_group, aircraft_model: super_model)

      airline_route_c = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_c)
      airline_route_a = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_a)
      airline_route_b = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_b)
      airline_route_d = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: maj.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_d)
      airline_route_other_game = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: other_game_airline)
      airplane_route_c = AirplaneRoute.new(airplane: airplane_c, route: airline_route_c, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_a = AirplaneRoute.new(airplane: airplane_a, route: airline_route_a, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_b = AirplaneRoute.new(airplane: airplane_b, route: airline_route_b, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_d = AirplaneRoute.new(airplane: airplane_d, route: airline_route_d, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_other_game = AirplaneRoute.new(airplane: airplane_other_game, route: airline_route_other_game, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)

      AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: other_airline)

      expect(AirlineRoute.operators_in_market(fun.market, inu.market, game)).to eq [airline_route_a, airline_route_b, airline_route_c, airline_route_d]
    end

    it "is empty if no airline operates the route" do
      game = Fabricate(:game)

      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      expect(AirlineRoute.operators_in_market(fun, inu, game)).to eq []
    end
  end

  context "operators_of_other_market_routes" do
    it "includes only routes from airlines that operate in the market and sorts them" do
      game = Fabricate(:game)
      other_game = Fabricate(:game)

      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)

      airline_c = Fabricate(:airline, base_id: inu.market.id, name: "C", game_id: game.id)
      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A", game_id: game.id)
      airline_b = Fabricate(:airline, base_id: inu.market.id, name: "B", game_id: game.id)
      airline_d = Fabricate(:airline, base_id: inu.market.id, name: "D", game_id: game.id)
      other_airline = Fabricate(:airline, base_id: inu.market.id, game_id: game.id)
      other_game_airline = Fabricate(:airline, base_id: inu.market.id, game_id: other_game.id)
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000)
      airplane_c = Fabricate(:airplane, aircraft_family: family, operator_id: airline_c.id, base_country_group: airline_c.base.country_group, aircraft_model: super_model)
      airplane_a = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model)
      airplane_b = Fabricate(:airplane, aircraft_family: family, operator_id: airline_b.id, base_country_group: airline_b.base.country_group, aircraft_model: super_model)
      airplane_d = Fabricate(:airplane, aircraft_family: family, operator_id: airline_d.id, base_country_group: airline_d.base.country_group, aircraft_model: super_model)
      airplane_other_game = Fabricate(:airplane, aircraft_family: family, operator_id: other_game_airline.id, base_country_group: other_game_airline.base.country_group, aircraft_model: super_model)

      airline_route_c = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_c)
      airline_route_a = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_a)
      airline_route_b = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_b)
      airline_route_d = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: maj.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_d)
      airline_route_other_game = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: other_game_airline)
      airplane_route_c = AirplaneRoute.new(airplane: airplane_c, route: airline_route_c, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_a = AirplaneRoute.new(airplane: airplane_a, route: airline_route_a, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_b = AirplaneRoute.new(airplane: airplane_b, route: airline_route_b, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_d = AirplaneRoute.new(airplane: airplane_d, route: airline_route_d, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_other_game = AirplaneRoute.new(airplane: airplane_other_game, route: airline_route_other_game, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)

      AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: other_airline)

      expect(AirlineRoute.operators_of_other_market_routes(fun, inu, game)).to eq [airline_route_d]
    end
  end

  context "operators_of_route" do
    it "includes only routes from airlines that operate the route and sorts them" do
      game = Fabricate(:game)
      other_game = Fabricate(:game)

      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      airline_c = Fabricate(:airline, base_id: inu.market.id, name: "C", game_id: game.id)
      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A", game_id: game.id)
      airline_b = Fabricate(:airline, base_id: inu.market.id, name: "B", game_id: game.id)
      other_airline = Fabricate(:airline, base_id: inu.market.id, game_id: game.id)
      other_game_airline = Fabricate(:airline, base_id: inu.market.id, game_id: other_game.id)
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000)
      airplane_c = Fabricate(:airplane, aircraft_family: family, operator_id: airline_c.id, base_country_group: airline_c.base.country_group, aircraft_model: super_model)
      airplane_a = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model)
      airplane_b = Fabricate(:airplane, aircraft_family: family, operator_id: airline_b.id, base_country_group: airline_b.base.country_group, aircraft_model: super_model)
      airplane_other_game = Fabricate(:airplane, aircraft_family: family, operator_id: other_game_airline.id, base_country_group: other_game_airline.base.country_group, aircraft_model: super_model)

      airline_route_c = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_c)
      airline_route_a = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_a)
      airline_route_b = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_b)
      airline_route_other_game = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: other_game_airline)
      airplane_route_c = AirplaneRoute.new(airplane: airplane_c, route: airline_route_c, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_a = AirplaneRoute.new(airplane: airplane_a, route: airline_route_a, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_b = AirplaneRoute.new(airplane: airplane_b, route: airline_route_b, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_other_game = AirplaneRoute.new(airplane: airplane_other_game, route: airline_route_other_game, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)

      AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: other_airline)

      expect(AirlineRoute.operators_of_route(fun, inu, game)).to eq [airline_route_a, airline_route_b, airline_route_c]
    end

    it "is empty if no airline operates the route" do
      game = Fabricate(:game)

      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      expect(AirlineRoute.operators_of_route(fun, inu, game)).to eq []
    end
  end

  context "airplanes_available_to_add_service" do
    it "calculates correctly" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)
      game = Game.find(airline.game_id)
      other_airline = Fabricate(:airline, base_id: fun.market.id, name: "Foo", game_id: game.id)
      other_game = Fabricate(:game)
      other_game_airline = Fabricate(:airline, base_id: inu.market.id, name: "Bar", game_id: other_game.id)
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000)
      incapable_model = Fabricate(:aircraft_model, takeoff_distance: 100000, max_range: 1)
      airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: super_model)
      other_airline_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: other_airline.id, base_country_group: other_airline.base.country_group, aircraft_model: super_model)
      other_game_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: other_game_airline.id, base_country_group: other_airline.base.country_group, aircraft_model: super_model)
      too_much_time_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: super_model)
      disconnected_network_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: super_model)
      incapable_of_airport_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: incapable_model)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline)
      other_airline_airline_route = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: other_airline)
      too_much_time_airline_route = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: trw.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline)
      too_much_time_route = AirplaneRoute.new(route: too_much_time_airline_route, airplane: too_much_time_airplane, frequencies: 10000, block_time_mins: 1441 * 7, flight_cost: 1).save(validate: false)
      disconnected_airline_route = AirlineRoute.create!(origin_airport_id: maj.id, destination_airport_id: trw.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline)
      disconnected_route = AirplaneRoute.new(route: disconnected_airline_route, airplane: disconnected_network_airplane, frequencies: 1, block_time_mins: 1, flight_cost: 1).save(validate: false)
      other_game_airline_route = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport: inu, economy_price: 1, premium_economy_price: 2, business_price: 4, airline: other_game_airline)
      other_game_route = AirplaneRoute.new(route: other_game_airline_route, airplane: other_game_airplane, frequencies: 1, block_time_mins: 2, flight_cost: 4).save(validate: false)
      subject.reload

      expect(subject.airplanes_available_to_add_service(game)).to eq [airplane]
      expect(other_airline_airline_route.airplanes_available_to_add_service(game)).to eq [other_airline_airplane]
    end
  end

  context "airline_can_fly_route" do
    it "is true when the airline can fly the route" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)

      subject = AirlineRoute.new(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline)

      expect(airline).to receive(:can_fly_between?).with(inu.market, inu.market).and_return(true)

      expect(subject.valid?).to be true
    end

    it "is false when the airline cannot fly the route" do
      inu_market = Fabricate(:market, name: "Nauru", country: "Nauru", country_group: "Nauru")
      inu = Fabricate(:airport, iata: "INU", market: inu_market)
      airline = Fabricate(:airline, base_id: inu_market.id)
      fun_market = Fabricate(:market, name: "Funafuti", country: "Tuvalu", country_group: "Tuvalu")
      fun = Fabricate(:airport, iata: "FUN", market: fun_market)
      RivalCountryGroup.create!(country_one: "Nauru", country_two: "Tuvalu")

      subject = AirlineRoute.new(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline)

      expect(airline).to receive(:can_fly_between?).with(fun_market, inu_market).and_return(false)

      expect(subject.valid?).to be false
    end
  end

  context "airports_alphabetized" do
    it "is true when the airports are alphabetized" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline)

      expect(subject.validate).to be true
    end

    it "is false when the airports are equal" do
      inu = Fabricate(:airport, iata: "INU")
      airline = Fabricate(:airline, base_id: inu.market.id)

      subject = AirlineRoute.create(origin_airport_id: inu.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline)

      expect(subject.validate).to be false
      expect(subject.errors.full_messages).to include "Destination airport must correspond to an airport with iata alphabetically after origin airport's iata"
    end

    it "is false when the airports are not alphabetized" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)

      subject = AirlineRoute.new(origin_airport_id: inu.id, destination_airport_id: fun.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Destination airport must correspond to an airport with iata alphabetically after origin airport's iata"
    end
  end

  context "find_or_create_by_airline_and_route" do
    it "returns the record if it already exists" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      airline_route = AirlineRoute.create!(economy_price: 1, premium_economy_price: 2, business_price: 3, origin_airport: fun, destination_airport: inu, airline: airline)

      original_record_count = AirlineRoute.count

      expect(AirlineRoute.find_or_create_by_airline_and_route(airline, fun, inu)).to eq airline_route
      expect(AirlineRoute.count).to eq original_record_count
    end

    it "assigns the record a price and creates it if it does not already exist" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      original_record_count = AirlineRoute.count

      inertia = instance_double(Calculation::InertiaRouteService, economy_fare: 1, business_fare: 0, premium_economy_fare: 1.5)
      route_dollars = instance_double(RouteDollars, distance: 1, business: 2, economy: 3, premium_economy: 4)
      allow(RouteDollars).to receive(:calculate).with(Date.today, fun.market, inu.market, nil, nil).and_return(route_dollars)
      expect(RouteDollars).to receive(:between_markets).with(fun.market, inu.market, Date.today).and_return([route_dollars])
      expect(Calculation::InertiaRouteService).to receive(:new).with(1, 2, 3, 4).and_return(inertia)

      actual = AirlineRoute.find_or_create_by_airline_and_route(airline, fun, inu)

      expect(actual.present?).to be true
      expect(AirlineRoute.count).to eq original_record_count + 1
    end
  end

  context "flight_profit" do
    it "is calculated correctly for a single plane" do
      airplane_1 = Airplane.new(economy_seats: 75, business_seats: 12, premium_economy_seats: 13)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, frequencies: 1, flight_cost: 200)
      subject = AirlineRoute.new(
        airplane_routes: [airplane_route_1],
        revenue: AirlineRouteRevenue.new(economy_pax: 10, business_pax: 12, premium_economy_pax: 13, revenue: 250, exclusive_economy_revenue: 20, exclusive_business_revenue: 30, exclusive_premium_economy_revenue: 1),
      )

      expect(subject.flight_profit).to eq 50 / 7.0
    end

    it "is calculated correctly for multiple planes and frequencies" do
      airplane_1 = Airplane.new(economy_seats: 75, business_seats: 12, premium_economy_seats: 13)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, frequencies: 1, flight_cost: 200)
      airplane_2 = Airplane.new(economy_seats: 70, business_seats: 10, premium_economy_seats: 20)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, frequencies: 2, flight_cost: 300)
      subject = AirlineRoute.new(
        airplane_routes: [airplane_route_1, airplane_route_2],
        revenue: AirlineRouteRevenue.new(economy_pax: 9, business_pax: 11, premium_economy_pax: 10, revenue: 250, exclusive_economy_revenue: 20, exclusive_business_revenue: 30, exclusive_premium_economy_revenue: 1),
      )

      expect(subject.flight_profit).to eq -550 / 7.0
    end
  end

  context "frequencies_on_airplane" do
    it "calculates correctly" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A")
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000)
      airplane_1 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model)
      airplane_2 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_a)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, route: subject, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, route: subject, block_time_mins: 1, frequencies: 2, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.frequencies_on_airplane(airplane_1)).to eq 1
      expect(subject.frequencies_on_airplane(airplane_2)).to eq 2
    end
  end

  context "load_factor" do
    it "is calculated correctly for a single plane" do
      airplane_1 = Airplane.new(economy_seats: 75, business_seats: 12, premium_economy_seats: 13)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, frequencies: 1)
      subject = AirlineRoute.new(
        airplane_routes: [airplane_route_1],
        revenue: AirlineRouteRevenue.new(economy_pax: 10, business_pax: 12, premium_economy_pax: 13),
      )

      expect(subject.load_factor).to eq 35.0
    end

    it "is calculated correctly for multiple planes and frequencies" do
      airplane_1 = Airplane.new(economy_seats: 75, business_seats: 12, premium_economy_seats: 13)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, frequencies: 1)
      airplane_2 = Airplane.new(economy_seats: 70, business_seats: 10, premium_economy_seats: 20)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, frequencies: 2)
      subject = AirlineRoute.new(
        airplane_routes: [airplane_route_1, airplane_route_2],
        revenue: AirlineRouteRevenue.new(economy_pax: 27, business_pax: 33, premium_economy_pax: 30),
      )

      expect(subject.load_factor).to eq 30.0
    end
  end

  context "name" do
    it "is the IATA codes separated by a dash" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      subject = AirlineRoute.new(origin_airport: fun, destination_airport: inu)
      expect(subject.name).to eq "FUN - INU"
    end
  end

  context "reputation" do
    let(:origin) { Fabricate(:airport, iata: "BOS") }
    let(:destination) { Fabricate(:airport, iata: "ORH", market: origin.market) }
    let(:airline) { Fabricate(:airline, base_id: destination.market.id) }
    let(:family) { Fabricate(:aircraft_family) }
    let(:model) { Fabricate(:aircraft_model, family: family, floor_space: Airplane::ECONOMY_SEAT_SIZE * 10) }
    let(:inertia) { instance_double(Calculation::InertiaRouteService, business_fare: 50000, economy_fare: 30000, premium_economy_fare: 45750) }
    let(:route_dollars) { instance_double(RouteDollars, distance: 1, business: 2, economy: 3, premium_economy: 4) }

    before(:each) do
      allow(RouteDollars).to receive(:calculate).with(Date.today, origin.market, destination.market, nil, nil).and_return(route_dollars)
      allow(RouteDollars).to receive(:between_markets).with(origin.market, destination.market, Date.today).and_return([route_dollars])
      allow(Calculation::InertiaRouteService).to receive(:new).with(1, 2, 3, 4).and_return(inertia)
    end

    it "is minimal for a minimal legroom reputation and a minimal in flight service reputation and a minimal fare reputation and a minimal frequency reputation" do
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 10)
      subject = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, airline: airline, economy_price: 50200, premium_economy_price: 81500, business_price: 50000)
      AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: airplane).save(validate: false)
      subject.reload

      expect(subject.reputation).to eq AirlineRoute::MIN_REPUTATION
    end

    it "is maximal for a maximal legroom reputation and a maximal in flight service reputation and maximal fare reputation and a maximal frequency reputation" do
      model.update(floor_space: 10000000000)
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 1)
      subject = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, service_quality: 5, airline: airline, economy_price: 0.01, premium_economy_price: 0.01, business_price: 0.01)
      AirplaneRoute.new(route: subject, frequencies: 245, block_time_mins: 1, flight_cost: 1, airplane: airplane).save(validate: false)
      subject.reload

      assert_in_epsilon subject.reputation, AirlineRoute::MAX_REPUTATION, 0.0000001
    end

    it "is weighted accurately between legroom, in flight service, and fare" do
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 10)
      subject = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, service_quality: 5, airline: airline, economy_price: 30000 / 2, premium_economy_price: 45750 / 2, business_price: 50000 / 2)
      AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: airplane).save(validate: false)
      subject.reload

      assert_in_epsilon subject.reputation, AirlineRoute::MIN_REPUTATION + (AirlineRoute::MAX_REPUTATION - AirlineRoute::MIN_REPUTATION) * 0.1 + (AirlineRoute::MAX_REPUTATION - AirlineRoute::MIN_REPUTATION) * 0.3 / 2, 0.0000001
    end

    it "is weighted accurately by seats" do
      model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 500000)
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 500000)
      other_airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 1)
      subject = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, airline: airline, economy_price: 30000, premium_economy_price: 45750, business_price: 50000)
      AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: airplane).save(validate: false)
      AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: other_airplane).save(validate: false)
      subject.reload

      expect(subject.reputation).to be < AirlineRoute::MAX_REPUTATION
      expect(subject.reputation).to be > AirlineRoute::MIN_REPUTATION
      assert_in_epsilon subject.reputation, AirlineRoute::MIN_REPUTATION, 0.01
    end

    it "calculates correctly when no airline operates a route" do
      model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 1)
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 1)
      airplane_route = AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: airplane)
      subject = AirlineRoute.new(
        origin_airport: origin,
        destination_airport: destination,
        airline: airline,
        economy_price: 30000,
        premium_economy_price: 45750,
        business_price: 50000,
        airplane_routes: [airplane_route],
        service_quality: 5,
      )

      expect(subject.reputation).to eq AirlineRoute::MIN_REPUTATION + (AirlineRoute::MAX_REPUTATION - AirlineRoute::MIN_REPUTATION) * AirlineRoute::REPUTATION_WEIGHTS[:ifs]
    end
  end

  context "set_price" do
    it "updates the price when the airline does not fly the route" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      subject = AirlineRoute.create!(economy_price: 1, premium_economy_price: 2, business_price: 3, origin_airport: fun, destination_airport: inu, airline: airline)

      expect(subject.revenue).to be nil

      subject.set_price(4, 5, 6)

      expect(subject.errors.full_messages.empty?).to be true

      subject.reload

      expect(subject.economy_price).to eq 4
      expect(subject.premium_economy_price).to eq 5
      expect(subject.business_price).to eq 6
      expect(subject.revenue).to be nil
    end

    it "updates the price when the airline flies the route" do
      inu_market = Fabricate(:market, name: "Nauru", country: "Nauru", country_group: "Nauru", income: 100000)
      fun_market = Fabricate(:market, name: "Funafuti", country: "Tuvalu", country_group: "Tuvalu", income: 20000)
      inu_population = Population.create!(year: 2000, population: 14000, market_id: inu_market.id)
      fun_population = Population.create!(year: 2003, population: 6000, market_id: fun_market.id)
      inu_tourists = Tourists.create!(year: 2000, volume: 1400, market_id: inu_market.id)
      fun_tourists = Tourists.create!(year: 2003, volume: 6300, market_id: fun_market.id)
      inu = Fabricate(:airport, iata: "INU", market: inu_market)
      fun = Fabricate(:airport, iata: "FUN", market: fun_market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      subject = AirlineRoute.create!(economy_price: 1, premium_economy_price: 2, business_price: 3, origin_airport: fun, destination_airport: inu, airline: airline)
      family = Fabricate(:aircraft_family)
      airplane = Fabricate(:airplane, operator_id: airline.id, base_country_group: airline.base.country_group, business_seats: 1, economy_seats: 1, premium_economy_seats: 1, aircraft_family: family)
      AirplaneRoute.new(airplane: airplane, route: subject, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
      AirlineRouteRevenue.create!(airline_route: subject, revenue: 12, exclusive_economy_revenue: 2, exclusive_business_revenue: 3, exclusive_premium_economy_revenue: 1, business_pax: 1, economy_pax: 1, premium_economy_pax: 1)
      route_dollars = instance_double(RouteDollars, origin_market: fun_market, destination_market: inu_market, origin_airport_iata: "FUN", destination_airport_iata: "INU", date: Date.today, distance: 1000, business: 100, economy: 100, premium_economy: 100)
      allow(RouteDollars).to receive(:calculate).with(Date.today, fun_market, inu_market, nil, nil).and_return(route_dollars)
      allow(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, Date.today).and_return([route_dollars])
      subject.reload

      expect(subject.revenue.revenue).to eq 12
      expect(subject.revenue.exclusive_economy_revenue).to eq 2
      expect(subject.revenue.exclusive_premium_economy_revenue).to eq 1
      expect(subject.revenue.exclusive_business_revenue).to eq 3
      expect(subject.revenue.business_pax).to eq 1
      expect(subject.revenue.economy_pax).to eq 1
      expect(subject.revenue.premium_economy_pax).to eq 1

      subject.set_price(4, 5, 6)

      expect(subject.errors.full_messages.empty?).to be true

      subject.reload

      expect(subject.economy_price).to eq 4
      expect(subject.premium_economy_price).to eq 5
      expect(subject.business_price).to eq 6
      expect(subject.revenue.revenue).to eq 30
      expect(subject.revenue.business_pax).to eq 1
      expect(subject.revenue.economy_pax).to eq 1
      expect(subject.revenue.premium_economy_pax).to eq 1
    end

    it "returns false if the update fails" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      subject = AirlineRoute.create!(economy_price: 1, premium_economy_price: 2, business_price: 3, origin_airport: fun, destination_airport: inu, airline: airline)

      subject.set_price(4, 5, -6)

      expect(subject.errors.full_messages).to include("Business price must be greater than 0")

      subject.reload
      expect(subject.economy_price).to eq 1
      expect(subject.premium_economy_price).to eq 2
      expect(subject.business_price).to eq 3
    end
  end

  context "set_service_quality" do
    it "updates the service quality, the flight costs on the airplane routes, and the revenue" do
      inu_market = Fabricate(:market, name: "Nauru", country: "Nauru")
      fun_market = Fabricate(:market, name: "Funafuti", country: "Tuvalu")
      inu = Fabricate(:airport, iata: "INU", market: inu_market)
      fun = Fabricate(:airport, iata: "FUN", market: fun_market)
      Population.create!(market_id: inu.market.id, year: 1999, population: 1000)
      Tourists.create!(market_id: inu.market.id, year: 1999, volume: 10000)
      Population.create!(market_id: fun.market.id, year: 1999, population: 1000)
      Tourists.create!(market_id: fun.market.id, year: 1999, volume: 10000)

      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A")
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000, floor_space: 100000)
      airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model, business_seats: 1, premium_economy_seats: 5, economy_seats: 30)
      game = Game.find(airline_a.game_id)
      route_dollars = instance_double(RouteDollars, origin_market: fun_market, destination_market: inu_market, origin_airport_iata: "FUN", destination_airport_iata: "INU", date: Date.today, distance: 1000, business: 100, economy: 100, premium_economy: 100)
      allow(RouteDollars).to receive(:calculate).with(Date.today, fun_market, inu_market, nil, nil).and_return(route_dollars)
      allow(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, Date.today).and_return([route_dollars])

      Gates.create!(airport: inu, game: game, current_gates: 10)
      Slot.create!(gates_id: Gates.last.id, lessee_id: airline_a.id)
      Gates.create!(airport: fun, game: game, current_gates: 10)
      Slot.create!(gates_id: Gates.last.id, lessee_id: airline_a.id)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, service_quality: 3, airline: airline_a)
      block_time = airplane.round_trip_block_time(subject.distance).round
      AirplaneRoute.new(airplane: airplane, route: subject, block_time_mins: block_time, frequencies: 1, flight_cost: 1).save(validate: false)
      subject.reload
      airplane_route = AirplaneRoute.last

      expect(subject.revenue).to be nil

      subject.set_service_quality(2)
      subject.reload
      airplane_route.reload

      expect(airplane_route.flight_cost).to be > 1
      expect(subject.service_quality).to eq 2
      expect(subject.revenue).not_to be nil
    end
  end

  context "total_business_seats" do
    it "is zero if there are no frequencies" do
      expect(AirlineRoute.new.total_business_seats).to eq 0
    end

    it "calculates correctly if there are frequencies" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A")
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000, floor_space: 100000)
      airplane_1 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model, business_seats: 1, premium_economy_seats: 5, economy_seats: 30)
      airplane_2 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model, business_seats: 2, premium_economy_seats: 4, economy_seats: 100)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_a)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, route: subject, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, route: subject, block_time_mins: 1, frequencies: 2, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.total_business_seats).to eq 5
    end
  end

  context "total_economy_seats" do
    it "is zero if there are no frequencies" do
      expect(AirlineRoute.new.total_economy_seats).to eq 0
    end

    it "calculates correctly if there are frequencies" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A")
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000, floor_space: 100000)
      airplane_1 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model, business_seats: 1, premium_economy_seats: 5, economy_seats: 30)
      airplane_2 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model, business_seats: 2, premium_economy_seats: 4, economy_seats: 100)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_a)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, route: subject, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, route: subject, block_time_mins: 1, frequencies: 2, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.total_economy_seats).to eq 230
    end
  end

  context "total_flight_costs" do
    it "is calculated correctly for a single plane" do
      airplane_route_1 = AirplaneRoute.new(flight_cost: 200, frequencies: 1)
      subject = AirlineRoute.new(
        airplane_routes: [airplane_route_1],
      )

      expect(subject.total_flight_costs).to eq 200
    end

    it "is calculated correctly for multiple planes and frequencies" do
      airplane_route_1 = AirplaneRoute.new(flight_cost: 200, frequencies: 1)
      airplane_route_2 = AirplaneRoute.new(flight_cost: 300, frequencies: 2)
      subject = AirlineRoute.new(
        airplane_routes: [airplane_route_1, airplane_route_2],
      )

      expect(subject.total_flight_costs).to eq 800
    end
  end

  context "total_frequencies" do
    it "calculates correctly" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A")
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000)
      airplane_1 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model)
      airplane_2 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_a)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, route: subject, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, route: subject, block_time_mins: 1, frequencies: 2, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.total_frequencies).to eq 3
    end

    it "is zero when there are no frequencies" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A")

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_a)

      expect(subject.total_frequencies).to eq 0
    end
  end

  context "total_premium_economy_seats" do
    it "is zero if there are no frequencies" do
      expect(AirlineRoute.new.total_premium_economy_seats).to eq 0
    end

    it "calculates correctly if there are frequencies" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A")
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000, floor_space: 100000)
      airplane_1 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model, business_seats: 1, premium_economy_seats: 5, economy_seats: 30)
      airplane_2 = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model, business_seats: 2, premium_economy_seats: 4, economy_seats: 100)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline_a)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, route: subject, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, route: subject, block_time_mins: 1, frequencies: 2, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.total_premium_economy_seats).to eq 13
    end
  end

  context "update_revenue" do
    it "sets revenue to zero when frequencies are zero" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      subject = AirlineRoute.create!(economy_price: 1, premium_economy_price: 2, business_price: 3, origin_airport: fun, destination_airport: inu, airline: airline)
      AirlineRouteRevenue.new(airline_route: subject, revenue: 1, exclusive_economy_revenue: 0.01, exclusive_business_revenue: 1, exclusive_premium_economy_revenue: 1, business_pax: 2, economy_pax: 3, premium_economy_pax: 4).save(validate: false)
      subject.reload

      subject.update_revenue

      result = subject.revenue

      expect(result.revenue).to eq 0
      expect(result.exclusive_economy_revenue).to eq 0
      expect(result.exclusive_premium_economy_revenue).to eq 0
      expect(result.exclusive_business_revenue).to eq 0
      expect(result.business_pax).to eq 0
      expect(result.economy_pax).to eq 0
      expect(result.premium_economy_pax).to eq 0
    end

    it "updates revenue when frequencies are nonzero" do
      inu_market = Fabricate(:market, name: "Nauru", country: "Nauru", country_group: "Nauru", income: 100000)
      fun_market = Fabricate(:market, name: "Funafuti", country: "Tuvalu", country_group: "Tuvalu", income: 20000)
      inu_population = Population.create!(year: 2000, population: 14000, market_id: inu_market.id)
      fun_population = Population.create!(year: 2003, population: 6000, market_id: fun_market.id)
      inu_tourists = Tourists.create!(year: 2000, volume: 1400, market_id: inu_market.id)
      fun_tourists = Tourists.create!(year: 2003, volume: 6300, market_id: fun_market.id)
      inu = Fabricate(:airport, iata: "INU", market: inu_market)
      fun = Fabricate(:airport, iata: "FUN", market: fun_market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      subject = AirlineRoute.create!(economy_price: 1, premium_economy_price: 2, business_price: 3, origin_airport: fun, destination_airport: inu, airline: airline)
      family = Fabricate(:aircraft_family)
      airplane = Fabricate(:airplane, operator_id: airline.id, base_country_group: airline.base.country_group, business_seats: 1, economy_seats: 1, premium_economy_seats: 1, aircraft_family: family)
      AirplaneRoute.new(airplane: airplane, route: subject, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
      AirlineRouteRevenue.new(airline_route: subject, revenue: 106, exclusive_economy_revenue: 105, exclusive_premium_economy_revenue: 100, exclusive_business_revenue: 1, business_pax: 10, economy_pax: 21, premium_economy_pax: 0).save(validate: false)
      route_dollars = instance_double(RouteDollars, origin_market: fun_market, destination_market: inu_market, origin_airport_iata: "FUN", destination_airport_iata: "INU", date: Date.today, distance: 1000, business: 100, economy: 100, premium_economy: 100)
      allow(RouteDollars).to receive(:calculate).with(Date.today, fun_market, inu_market, nil, nil).and_return(route_dollars)
      allow(RouteDollars).to receive(:between_markets).with(fun_market, inu_market, Date.today).and_return([route_dollars])
      subject.reload

      subject.update_revenue

      result = subject.revenue

      expect(result.revenue).to eq 12
      expect(result.business_pax).to eq 1
      expect(result.economy_pax).to eq 1
      expect(result.premium_economy_pax).to eq 1
    end
  end
end
