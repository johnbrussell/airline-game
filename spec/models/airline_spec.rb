require "rails_helper"

RSpec.describe Airline do
  context "at_airport" do
    it "returns empty when no airlines serve an airport" do
      airport = Fabricate(:airport)
      game = Fabricate(:game)

      expect(Airline.at_airport(airport, game)).to eq []
    end

    it "finds all airlines that serve the airport" do
      game = Fabricate(:game)
      other_game = Fabricate(:game)

      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, market: inu.market, iata: "FUN")
      maj = Fabricate(:airport, market: inu.market, iata: "MAJ")

      airline = Fabricate(:airline, game_id: game.id, base_id: Airport.last.market.id)
      other_airline = Fabricate(:airline, game_id: game.id, base_id: Airport.last.market.id)
      other_game_airline = Fabricate(:airline, game_id: other_game.id, base_id: Airport.last.market.id)

      inu_gates = Gates.create!(game: game, airport: inu, current_gates: 10)
      fun_gates = Gates.create!(game: game, airport: fun, current_gates: 10)
      maj_gates = Gates.create!(game: game, airport: maj, current_gates: 10)
      other_inu_gates = Gates.create!(game: other_game, airport: inu, current_gates: 10)
      other_fun_gates = Gates.create!(game: other_game, airport: fun, current_gates: 10)
      other_maj_gates = Gates.create!(game: other_game, airport: maj, current_gates: 10)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: maj_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: other_airline.id)
      Slot.create!(gates: maj_gates, lessee_id: other_airline.id)
      Slot.create!(gates: other_maj_gates, lessee_id: other_game_airline.id)
      Slot.create!(gates: other_fun_gates, lessee_id: other_game_airline.id)
      Slot.create!(gates: other_inu_gates, lessee_id: other_game_airline.id)

      expect(Airline.at_airport(inu, game)).to eq [airline]
      expect(Airline.at_airport(fun, game)).to eq [airline, other_airline]
      expect(Airline.at_airport(maj, game)).to eq [airline, other_airline]
      expect(Airline.at_airport(fun, other_game)).to eq [other_game_airline]
      expect(Airline.at_airport(inu, other_game)).to eq [other_game_airline]
      expect(Airline.at_airport(maj, other_game)).to eq [other_game_airline]
    end
  end

  context "can_fly_between?" do
    it "is true when flying a route within its home country group" do
      origins = [
        Fabricate(:market, name: "New York", income: 1, country: "United States", country_group: "USA"),
        Fabricate(:market, name: "Pohnpei", income: 1, country: "Micronesia", country_group: "USA"),
        Fabricate(:market, name: "Pago Pago", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States"),
      ]
      destinations = [
        Fabricate(:market, name: "Boston", income: 1, country: "United States", country_group: "USA"),
        Fabricate(:market, name: "Majuro", income: 1, country: "Marshall Islands", country_group: "USA"),
        Fabricate(:market, name: "Yap", income: 1, country: "Micronesia", country_group: "USA"),
        Fabricate(:market, name: "Saipan", income: 1, country: "Northern Mariana Islands", country_group: "USA", territory_of: "United States"),
        Fabricate(:market, name: "Fitiuta", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States"),
      ]

      subject = Fabricate(:airline, base_id: (origins + destinations).sample.id)

      expect(subject.can_fly_between?(origins.sample, destinations.sample)).to be true
    end

    it "is true when flying between country groups" do
      origin = Fabricate(:market, name: "Nauru", income: 1, country: "Nauru", country_group: "Nauru")
      destination = Fabricate(:market, name: "Funafuti", income: 1, country: "Tuvalu", country_group: "Tuvalu")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is true when flying between countries within another country group" do
      origin = Fabricate(:market, name: "Nauru", income: 1, country: "Nauru", country_group: "Nauru and Tuvalu")
      destination = Fabricate(:market, name: "Funafuti", income: 1, country: "Tuvalu", country_group: "Nauru and Tuvalu")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is false when flying between rival countries" do
      origin = Fabricate(:market, name: "Nauru", income: 1, country: "Nauru", country_group: "Nauru")
      destination = Fabricate(:market, name: "Funafuti", income: 1, country: "Tuvalu", country_group: "Tuvalu")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")
      RivalCountryGroup.create!(country_one: "Nauru", country_two: "Tuvalu")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
    end

    it "is false when flying to a country that is rivals with the airline's home country" do
      origin = Fabricate(:market, name: "Nauru", income: 1, country: "Nauru", country_group: "Nauru")
      destination = Fabricate(:market, name: "Funafuti", income: 1, country: "Tuvalu", country_group: "Tuvalu")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")
      RivalCountryGroup.create!(country_one: "Kiribati", country_two: "Nauru")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
    end

    it "is false flying within a foreign country" do
      origin = Fabricate(:market, name: "Nauru", income: 1, country: "Nauru and Tuvalu", country_group: "Nauru and Tuvalu")
      destination = Fabricate(:market, name: "Funafuti", income: 1, country: "Nauru and Tuvalu", country_group: "Nauru and Tuvalu")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
    end

    it "is false flying from a foreign country to one of its territories" do
      origin = Fabricate(:market, name: "Ponce", income: 1, country: "Puerto Rico", country_group: "USA", territory_of: "United States")
      destination = Fabricate(:market, name: "Adak", income: 1, country: "United States", country_group: "USA")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
    end

    it "is false flying between territories of a foreign country" do
      origin = Fabricate(:market, name: "Ponce", income: 1, country: "Puerto Rico", country_group: "USA", territory_of: "United States")
      destination = Fabricate(:market, name: "Pago Pago", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
    end

    it "is true flying within a foreign country in the presence of a general exception" do
      CabotageException.create!(country: "Nauru and Tuvalu")
      origin = Fabricate(:market, name: "Nauru", income: 1, country: "Nauru and Tuvalu", country_group: "Nauru and Tuvalu")
      destination = Fabricate(:market, name: "Funafuti", income: 1, country: "Nauru and Tuvalu", country_group: "Nauru and Tuvalu")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is true flying within a foreign country in the presence of a specific exception" do
      CabotageException.create!(country: "Nauru and Tuvalu", excepted_country_group: "Kiribati")
      origin = Fabricate(:market, name: "Nauru", income: 1, country: "Nauru and Tuvalu", country_group: "Nauru and Tuvalu")
      destination = Fabricate(:market, name: "Funafuti", income: 1, country: "Nauru and Tuvalu", country_group: "Nauru and Tuvalu")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is true flying from a foreign country to one of its territories in the presence of a general exception" do
      CabotageException.create!(country: "United States")
      origin = Fabricate(:market, name: "Ponce", income: 1, country: "Puerto Rico", country_group: "USA", territory_of: "United States")
      destination = Fabricate(:market, name: "Adak", income: 1, country: "United States", country_group: "USA")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is true flying from a foreign country to one of its territories in the presence of a specific exception" do
      CabotageException.create!(country: "United States", excepted_country_group: "Kiribati")
      origin = Fabricate(:market, name: "Ponce", income: 1, country: "Puerto Rico", country_group: "USA", territory_of: "United States")
      destination = Fabricate(:market, name: "Adak", income: 1, country: "United States", country_group: "USA")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is true flying between territories of a foreign country in the presence of a general exception" do
      CabotageException.create!(country: "United States")
      origin = Fabricate(:market, name: "Ponce", income: 1, country: "Puerto Rico", country_group: "USA", territory_of: "United States")
      destination = Fabricate(:market, name: "Pago Pago", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is true flying between territories of a foreign country in the presence of a specific exception" do
      CabotageException.create!(country: "United States", excepted_country_group: "Kiribati")
      origin = Fabricate(:market, name: "Ponce", income: 1, country: "Puerto Rico", country_group: "USA", territory_of: "United States")
      destination = Fabricate(:market, name: "Pago Pago", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is true flying within the territory of a foreign country but false flying within the foreign country in the presence of a general exception" do
      CabotageException.create!(country: "American Samoa")
      origin = Fabricate(:market, name: "Fitiuta", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States")
      destination = Fabricate(:market, name: "Pago Pago", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States")
      other_destination = Fabricate(:market, name: "Guam", income: 1, country: "Guam", country_group: "USA", territory_of: "United States")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
      expect(subject.can_fly_between?(origin, other_destination)).to be false
      expect(subject.can_fly_between?(other_destination, origin)).to be false
    end

    it "is true flying within the territory of a foreign country but false flying within the foreign country in the presence of a specific exception" do
      CabotageException.create!(country: "American Samoa", excepted_country_group: "Kiribati")
      origin = Fabricate(:market, name: "Fitiuta", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States")
      destination = Fabricate(:market, name: "Pago Pago", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States")
      other_destination = Fabricate(:market, name: "Guam", income: 1, country: "Guam", country_group: "USA", territory_of: "United States")
      base = Fabricate(:market, name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
      expect(subject.can_fly_between?(origin, other_destination)).to be false
      expect(subject.can_fly_between?(other_destination, origin)).to be false
    end
  end

  context "only_one_user_airline_exists" do
    it "is true when creating a non-user airline and no user airline exists" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: false, base_id: 1, game_id: 1)
      Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: false, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 2
    end

    it "is true when creating a non-user airline and a user airline exists" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, base_id: 1, game_id: 1)
      Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: false, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 2
    end

    it "is true when creating the only user airline" do
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: false, base_id: 1, game_id: 1)
      Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: true, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 2
    end

    it "is true when creating an airline and a user airline exists in another game" do
      game = Game.create!(start_date: Date.yesterday, end_date: Date.tomorrow, current_date: Date.today)
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, game_id: game.id, base_id: 1)

      new_game = Game.create!(start_date: Date.yesterday, end_date: Date.tomorrow, current_date: Date.today)
      new_airline = Airline.new(cash_on_hand: 1, name: "bar", is_user_airline: true, game_id: new_game.id, base_id: 1)

      expect(new_airline.valid?).to be true
      expect(new_airline.save).to be true
      expect(Airline.count).to eq 2
    end

    it "is true when updating an airline" do
      airline = Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, base_id: 1, game_id: 1)

      expect(airline.update(name: "bar")).to eq true
    end

    it "is false when creating an airline and a user airline exists in the game" do
      game = Game.create!(start_date: Date.yesterday, end_date: Date.tomorrow, current_date: Date.today)
      Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, game_id: game.id, base_id: 1)

      new_airline = Airline.new(cash_on_hand: 1, name: "bar", is_user_airline: true, game_id: game.id, base_id: 1)

      expect(new_airline.valid?).to be false
      expect(new_airline.save).to be false
      expect(new_airline.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include ("is_user_airline cannot be true for multiple airlines within a game")
    end
  end

  context "rival_country_groups" do
    it "lists the airline's rival country groups" do
      subject = Fabricate(:airline)
      home_country_group = subject.base.country_group

      expect(subject.rival_country_groups).to eq []

      RivalCountryGroup.create!(country_one: home_country_group, country_two: "Zanzibar")
      subject.reload

      expect(subject.rival_country_groups).to eq ["Zanzibar"]
    end
  end

  context "routes" do
    it "includes all routes with service" do
      airline = Fabricate(:airline)
      family = Fabricate(:aircraft_family)
      airplane_1 = Fabricate(:airplane, aircraft_family: family)
      airplane_2 = Fabricate(:airplane, aircraft_family: family)

      airport_1 = Fabricate(:airport, market: airline.base, iata: "AAA")
      airport_2 = Fabricate(:airport, market: airline.base, iata: "BBB")
      airport_3 = Fabricate(:airport, market: airline.base, iata: "CCC")
      airport_4 = Fabricate(:airport, market: airline.base, iata: "DDD")

      AirlineRoute.new(airline: airline, origin_airport: airport_2, destination_airport: airport_3, economy_price: 1, business_price: 2, premium_economy_price: 3).save(validate: false)
      route_1 = AirlineRoute.last
      AirplaneRoute.new(route: route_1, airplane: airplane_1, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
      AirlineRoute.new(airline: airline, origin_airport: airport_1, destination_airport: airport_4, economy_price: 1, business_price: 2, premium_economy_price: 3).save(validate: false)
      route_2 = AirlineRoute.last
      AirplaneRoute.new(route: route_2, airplane: airplane_2, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
      AirlineRoute.new(airline: airline, origin_airport: airport_1, destination_airport: airport_3, economy_price: 1, business_price: 2, premium_economy_price: 3).save(validate: false)

      airline.reload

      expect(airline.routes).to eq [route_2, route_1]
    end
  end

  context "routes_at_airport" do
    it "includes both origins and destinations and excludes routes with no service" do
      airline = Fabricate(:airline)
      family = Fabricate(:aircraft_family)
      airplane = Fabricate(:airplane, aircraft_family: family)

      airport_1 = Fabricate(:airport, market: airline.base, iata: "AAA")
      airport_2 = Fabricate(:airport, market: airline.base, iata: "BBB")
      airport_3 = Fabricate(:airport, market: airline.base, iata: "CCC")
      airport_4 = Fabricate(:airport, market: airline.base, iata: "DDD")

      AirlineRoute.new(airline: airline, origin_airport: airport_2, destination_airport: airport_3, economy_price: 1, business_price: 2, premium_economy_price: 3).save(validate: false)
      route_1 = AirlineRoute.last
      AirplaneRoute.new(route: route_1, airplane: airplane, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
      AirlineRoute.new(airline: airline, origin_airport: airport_1, destination_airport: airport_2, economy_price: 1, business_price: 2, premium_economy_price: 3).save(validate: false)
      route_2 = AirlineRoute.last
      AirplaneRoute.new(route: route_2, airplane: airplane, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
      AirlineRoute.new(airline: airline, origin_airport: airport_1, destination_airport: airport_3, economy_price: 1, business_price: 2, premium_economy_price: 3).save(validate: false)

      airline.reload

      expect(airline.routes_at_airport(airport_1)).to eq [route_2]
      expect(airline.routes_at_airport(airport_2)).to eq [route_2, route_1]
      expect(airline.routes_at_airport(airport_3)).to eq [route_1]
      expect(airline.routes_at_airport(airport_4)).to eq []
    end
  end

  context "validate_a_user_airline_exists" do
    it "is false for a user airline" do
      airline = Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: true, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 1
      airline.destroy
      expect(Airline.count).to eq 1
      expect(airline.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include "is_user_airline must be true for at least one airline at all times"
    end

    it "is true for a non-user airline" do
      airline_1 = Airline.create!(cash_on_hand: 1, name: "foo", is_user_airline: false, base_id: 1, game_id: 1)
      airline_2 = Airline.create!(cash_on_hand: 1, name: "bar", is_user_airline: true, base_id: 1, game_id: 1)

      expect(Airline.count).to eq 2
      airline_1.destroy
      expect(Airline.count).to eq 1

      expect(Airline.last.id).to eq airline_2.id
    end
  end
end
