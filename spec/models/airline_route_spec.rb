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
      other_airline = Fabricate(:airline, base_id: fun.market.id, name: "Foo")
      family = Fabricate(:aircraft_family)
      super_model = Fabricate(:aircraft_model, takeoff_distance: 100, max_range: 13000)
      incapable_model = Fabricate(:aircraft_model, takeoff_distance: 100000, max_range: 1)
      airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: super_model)
      other_airline_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: other_airline.id, base_country_group: other_airline.base.country_group, aircraft_model: super_model)
      too_much_time_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: super_model)
      disconnected_network_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: super_model)
      incapable_of_airport_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, aircraft_model: incapable_model)

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)
      other_airline_airline_route = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: other_airline)
      too_much_time_airline_route = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: trw.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)
      too_much_time_route = AirplaneRoute.new(route: too_much_time_airline_route, airplane: too_much_time_airplane, frequencies: 10000, block_time_mins: 1441 * 7, flight_cost: 1).save(validate: false)
      disconnected_airline_route = AirlineRoute.create!(origin_airport_id: maj.id, destination_airport_id: trw.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)
      disconnected_route = AirplaneRoute.new(route: disconnected_airline_route, airplane: disconnected_network_airplane, frequencies: 1, block_time_mins: 1, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.airplanes_available_to_add_service).to eq [airplane]
      expect(other_airline_airline_route.airplanes_available_to_add_service).to eq [other_airline_airplane]
    end
  end

  context "airline_can_fly_route" do
    it "is true when the airline can fly the route" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id)

      subject = AirlineRoute.new(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)

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

      subject = AirlineRoute.new(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)

      expect(airline).to receive(:can_fly_between?).with(fun_market, inu_market).and_return(false)

      expect(subject.valid?).to be false
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
      airline = Fabricate(:airline, base_id: inu.market.id)

      subject = AirlineRoute.create(origin_airport_id: inu.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline)

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

  context "find_or_create_by_airline_and_route" do
    it "returns the record if it already exists" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      airline_route = AirlineRoute.create!(economy_price: 1, distance: 2, premium_economy_price: 2, business_price: 3, origin_airport: fun, destination_airport: inu, airline: airline)

      original_record_count = AirlineRoute.count

      expect(AirlineRoute.find_or_create_by_airline_and_route(airline, fun, inu)).to eq airline_route
      expect(AirlineRoute.count).to eq original_record_count
    end

    it "assigns the record a price and creates it if it does not already exist" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      original_record_count = AirlineRoute.count

      actual = AirlineRoute.find_or_create_by_airline_and_route(airline, fun, inu)

      expect(actual.present?).to be true
      expect(AirlineRoute.count).to eq original_record_count + 1
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

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline_a)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, route: subject, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, route: subject, block_time_mins: 1, frequencies: 2, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.frequencies_on_airplane(airplane_1)).to eq 1
      expect(subject.frequencies_on_airplane(airplane_2)).to eq 2
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

    before(:each) do
      allow(Calculation::InertiaRouteService).to receive(:new).with(origin, destination, Game.find(airline.game_id).current_date).and_return(inertia)
    end

    it "is minimal for a minimal legroom reputation and a minimal in flight service reputation and a minimal fare reputation" do
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 10)
      subject = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, distance: 1, airline: airline, economy_price: 50200, premium_economy_price: 81500, business_price: 50000)
      AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: airplane).save(validate: false)
      subject.reload

      expect(subject.reputation).to eq AirlineRoute::MIN_REPUTATION
    end

    it "is maximal for a maximal legroom reputation and a maximal in flight service reputation and maximal fare reputation" do
      model.update(floor_space: 10000000000)
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 1)
      subject = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, distance: 1, service_quality: 5, airline: airline, economy_price: 0.01, premium_economy_price: 0.01, business_price: 0.01)
      AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: airplane).save(validate: false)
      subject.reload

      assert_in_epsilon subject.reputation, AirlineRoute::MAX_REPUTATION, 0.0000001
    end

    it "is weighted accurately between legroom, in flight service, and fare" do
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 10)
      subject = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, distance: 1, service_quality: 5, airline: airline, economy_price: 30000 / 2, premium_economy_price: 45750 / 2, business_price: 50000 / 2)
      AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: airplane).save(validate: false)
      subject.reload

      assert_in_epsilon subject.reputation, AirlineRoute::MIN_REPUTATION + (AirlineRoute::MAX_REPUTATION - AirlineRoute::MIN_REPUTATION) * 0.1 + (AirlineRoute::MAX_REPUTATION - AirlineRoute::MIN_REPUTATION) * 0.45 / 2, 0.0000001
    end

    it "is weighted accurately by seats" do
      model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 50000)
      airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 50000)
      other_airplane = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 1)
      subject = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, distance: 1, airline: airline, economy_price: 30000, premium_economy_price: 45750, business_price: 50000)
      AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: airplane).save(validate: false)
      AirplaneRoute.new(route: subject, frequencies: 1, block_time_mins: 1, flight_cost: 1, airplane: other_airplane).save(validate: false)
      subject.reload

      expect(subject.reputation).to be < AirlineRoute::MAX_REPUTATION
      expect(subject.reputation).to be > AirlineRoute::MIN_REPUTATION
      assert_in_epsilon subject.reputation, AirlineRoute::MIN_REPUTATION, 0.00001
    end
  end

  context "set_price" do
    it "updates the price" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      subject = AirlineRoute.create!(economy_price: 1, distance: 2, premium_economy_price: 2, business_price: 3, origin_airport: fun, destination_airport: inu, airline: airline)

      expect(subject.set_price(4, 5, 6)).to be true
      subject.reload

      expect(subject.economy_price).to eq 4
      expect(subject.premium_economy_price).to eq 5
      expect(subject.business_price).to eq 6
    end

    it "returns false if the update fails" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      airline = Fabricate(:airline, base_id: inu.market.id, name: "A")
      subject = AirlineRoute.create!(economy_price: 1, distance: 2, premium_economy_price: 2, business_price: 3, origin_airport: fun, destination_airport: inu, airline: airline)

      expect(subject.set_price(4, 5, -6)).to be false

      expect(subject.errors.full_messages).to include("Business price must be greater than 0")

      subject.reload
      expect(subject.economy_price).to eq 1
      expect(subject.premium_economy_price).to eq 2
      expect(subject.business_price).to eq 3
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

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline_a)
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

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline_a)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, route: subject, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, route: subject, block_time_mins: 1, frequencies: 2, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.total_economy_seats).to eq 230
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

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline_a)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, route: subject, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, route: subject, block_time_mins: 1, frequencies: 2, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.total_frequencies).to eq 3
    end

    it "is zero when there are no frequencies" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      airline_a = Fabricate(:airline, base_id: inu.market.id, name: "A")

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline_a)

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

      subject = AirlineRoute.create!(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4, airline: airline_a)
      airplane_route_1 = AirplaneRoute.new(airplane: airplane_1, route: subject, block_time_mins: 1, frequencies: 1, flight_cost: 1).save(validate: false)
      airplane_route_2 = AirplaneRoute.new(airplane: airplane_2, route: subject, block_time_mins: 1, frequencies: 2, flight_cost: 1).save(validate: false)
      subject.reload

      expect(subject.total_premium_economy_seats).to eq 13
    end
  end
end
