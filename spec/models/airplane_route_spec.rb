require "rails_helper"

RSpec.describe AirplaneRoute do
  context "routes_connected" do
    it "is true if the airplane has no other routes" do
      family = Fabricate(:aircraft_family)
      airplane = Fabricate(:airplane, aircraft_family: family)
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
      airplane = Fabricate(:airplane, aircraft_family: family)
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
      airplane = Fabricate(:airplane, aircraft_family: family)
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
end
