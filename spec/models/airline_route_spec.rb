require "rails_helper"

RSpec.describe AirlineRoute do
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
