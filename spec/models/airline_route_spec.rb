require "rails_helper"

RSpec.describe AirlineRoute do
  context "operators_of_route" do
    it "includes only routes from airlines that operate the route and sorts them" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      airline_c = Fabricate(:airline, base_id: inu.market.id, name: "C")
      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A")
      airline_b = Fabricate(:airline, base_id: inu.market.id, name: "B")
      other_airline = Fabricate(:airline, base_id: inu.market.id)
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000)
      airplane_c = Fabricate(:airplane, aircraft_family: family, operator_id: airline_c.id, base_country_group: airline_c.base.country_group, aircraft_model: super_model)
      airplane_a = Fabricate(:airplane, aircraft_family: family, operator_id: airline_a.id, base_country_group: airline_a.base.country_group, aircraft_model: super_model)
      airplane_b = Fabricate(:airplane, aircraft_family: family, operator_id: airline_b.id, base_country_group: airline_b.base.country_group, aircraft_model: super_model)

      airline_route_c = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline_c)
      airline_route_a = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline_a)
      airline_route_b = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline_b)
      airplane_route_c = AirplaneRoute.new(airplane: airplane_c, route: airline_route_c, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_a = AirplaneRoute.new(airplane: airplane_a, route: airline_route_a, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_b = AirplaneRoute.new(airplane: airplane_b, route: airline_route_b, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)

      AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: other_airline)

      expect(AirlineRoute.operators_of_route(fun, inu)).to eq [airline_route_a, airline_route_b, airline_route_c]
    end

    it "is empty if no airline operates the route" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      expect(AirlineRoute.operators_of_route(fun, inu)).to eq []
    end
  end

  context "airplanes_available_to_add_service" do
    it "calculates correctly" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000)
      incapable_model = Fabricate(:aircraft_model, takeoff_distance: 100000, max_range: 1)
      airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: super_model)
      too_much_time_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: super_model)
      disconnected_network_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: super_model)
      incapable_of_airport_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: incapable_model)

      airline_route = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)
      too_much_time_route = AirplaneRoute.new(route: airline_route, airplane: too_much_time_airplane, frequencies: 10000, block_time_mins: 1441 * 7, flight_cost: 1).save(validate: false)
      disconnected_airline_route = AirlineRoute.create!(origin_airport_id: maj.id, destination_airport_id: trw.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)
      disconnected_route = AirplaneRoute.new(route: disconnected_airline_route, airplane: disconnected_network_airplane, frequencies: 1, block_time_mins: 1, flight_cost: 1).save(validate: false)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)

      expect(subject.airplanes_available_to_add_service).to eq [airplane]
    end
  end

  context "airports_alphabetized" do
    it "is true when the airports are alphabetized" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)

      expect(subject.validate).to be true
    end

    it "is false when the airports are equal" do
      inu = Fabricate(:airport, iata: "INU")

      subject = AirlineRoute.create(origin_airport_id: inu.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4)

      expect(subject.validate).to be false
      expect(subject.errors.full_messages).to include "Destination airport must correspond to an airport with iata alphabetically after origin airport's iata"
    end

    it "is false when the airports are not alphabetized" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)

      subject = AirlineRoute.new(origin_airport_id: inu.id, destination_airport_id: fun.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Destination airport must correspond to an airport with iata alphabetically after origin airport's iata"
    end
  end
end
