require "rails_helper"

RSpec.describe AirlineRoute do
  context "airports_alphabetized" do
    it "is true when the airports are alphabetized" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)

      subject = AirlineRoute.create(origin_airport_id: fun.id, destination_airport_id: inu.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4)

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

      subject = AirlineRoute.create(origin_airport_id: inu.id, destination_airport_id: fun.id, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 4)

      expect(subject.validate).to be false
      expect(subject.errors.full_messages).to include "Destination airport must correspond to an airport with iata alphabetically after origin airport's iata"
    end
  end
end
