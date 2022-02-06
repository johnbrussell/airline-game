require "rails_helper"

RSpec.describe AirplaneRoute do
  context "airplane_can_fly_route" do
    it "is true when the airplane can fly the route" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 411)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: 100, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be true
    end

    it "is false when the airplane cannot fly the route" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9996, elevation: 0, market: market)
      airport_3 = Fabricate(:airport, iata: "TRW", latitude: 10, longitude: 12, runway: 11000, elevation: 0, market: market)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      airplane = Fabricate(:airplane, aircraft_family: family, economy_seats: 1, aircraft_model: model)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_3.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: distance - 1)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: 100, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be true
      subject.save

      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: distance)
      subject = AirplaneRoute.new(route: airline_route, airplane: airplane, block_time_mins: 100, flight_cost: 1, frequencies: 1)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Airplane cannot fly this route"
    end
  end

  context "airplane_time_is_logical" do
    it "is correct if the route is the only route for the airplane" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      subject = AirplaneRoute.create(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )

      expect(subject.valid?).to be true

      expect(subject.update(block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS + 1)).to be false
      expect(subject.errors.full_messages).to include "Airplane has too much block time"
    end

    it "is correct if the airplane has other routes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      other_route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      subject_1 = AirplaneRoute.create!(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: other_route,
      )
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: trw,
        distance: 1,
      )
      subject_2 = AirplaneRoute.create!(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )
      subject_1.reload
      subject_2.reload

      expect(subject_1.valid?).to be true
      expect(subject_2.valid?).to be true

      expect(subject_1.update(block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2 + 2)).to be false
      expect(subject_1.errors.full_messages).to include "Airplane has too much block time"
      expect(subject_2.update(block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2 + 2)).to be false
      expect(subject_2.errors.full_messages).to include "Airplane has too much block time"
    end
  end

  context "routes_connected" do
    it "is true if the airplane has no other routes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      subject = AirplaneRoute.new(
        block_time_mins: 1,
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
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
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
        distance: 1,
      )
      subject = AirplaneRoute.new(
        block_time_mins: 1,
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
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
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
        distance: 1,
      )
      subject = AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: airplane,
        route: route,
      )

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Route does not connect to airplane's route network"
    end
  end

  context "validate_remaining_routes_connected" do
    it "is true if the airplane has no other routes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      subject = AirplaneRoute.create(
        block_time_mins: 1,
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
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
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
        distance: 1,
      )
      subject = AirplaneRoute.create(
        block_time_mins: 1,
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
      airplane = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      subject = AirplaneRoute.create(
        block_time_mins: 1,
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
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
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
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
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
