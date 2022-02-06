require "rails_helper"

RSpec.describe Airline do
  context "can_fly_between?" do
    it "is true when flying a route within its home country group" do
      origins = [
        Market.create!(name: "New York", income: 1, country: "United States", country_group: "USA"),
        Market.create!(name: "Pohnpei", income: 1, country: "Micronesia", country_group: "USA"),
        Market.create!(name: "Pago Pago", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States"),
      ]
      destinations = [
        Market.create!(name: "Boston", income: 1, country: "United States", country_group: "USA"),
        Market.create!(name: "Majuro", income: 1, country: "Marshall Islands", country_group: "USA"),
        Market.create!(name: "Yap", income: 1, country: "Micronesia", country_group: "USA"),
        Market.create!(name: "Saipan", income: 1, country: "Northern Mariana Islands", country_group: "USA", territory_of: "United States"),
        Market.create!(name: "Fitiuta", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States"),
      ]

      subject = Fabricate(:airline, base_id: (origins + destinations).sample.id)

      expect(subject.can_fly_between?(origins.sample, destinations.sample)).to be true
    end

    it "is true when flying between country groups" do
      origin = Market.create!(name: "Nauru", income: 1, country: "Nauru", country_group: "Nauru")
      destination = Market.create!(name: "Funafuti", income: 1, country: "Tuvalu", country_group: "Tuvalu")
      base = Market.create!(name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is true when flying between countries within another country group" do
      origin = Market.create!(name: "Nauru", income: 1, country: "Nauru", country_group: "Nauru and Tuvalu")
      destination = Market.create!(name: "Funafuti", income: 1, country: "Tuvalu", country_group: "Nauru and Tuvalu")
      base = Market.create!(name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be true
      expect(subject.can_fly_between?(destination, origin)).to be true
    end

    it "is false when flying between rival countries" do
      origin = Market.create!(name: "Nauru", income: 1, country: "Nauru", country_group: "Nauru")
      destination = Market.create!(name: "Funafuti", income: 1, country: "Tuvalu", country_group: "Tuvalu")
      base = Market.create!(name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")
      RivalCountryGroup.create!(country_one: "Nauru", country_two: "Tuvalu")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
    end

    it "is false when flying to a country that is rivals with the airline's home country" do
      origin = Market.create!(name: "Nauru", income: 1, country: "Nauru", country_group: "Nauru")
      destination = Market.create!(name: "Funafuti", income: 1, country: "Tuvalu", country_group: "Tuvalu")
      base = Market.create!(name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")
      RivalCountryGroup.create!(country_one: "Kiribati", country_two: "Nauru")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
    end

    it "is false flying within a foreign country" do
      origin = Market.create!(name: "Nauru", income: 1, country: "Nauru and Tuvalu", country_group: "Nauru and Tuvalu")
      destination = Market.create!(name: "Funafuti", income: 1, country: "Nauru and Tuvalu", country_group: "Nauru and Tuvalu")
      base = Market.create!(name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
    end

    it "is false flying from a foreign country to one of its territories" do
      origin = Market.create!(name: "Ponce", income: 1, country: "Puerto Rico", country_group: "USA", territory_of: "United States")
      destination = Market.create!(name: "Adak", income: 1, country: "United States", country_group: "USA")
      base = Market.create!(name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
    end

    it "is false flying between territories of a foreign country" do
      origin = Market.create!(name: "Ponce", income: 1, country: "Puerto Rico", country_group: "USA", territory_of: "United States")
      destination = Market.create!(name: "Pago Pago", income: 1, country: "American Samoa", country_group: "USA", territory_of: "United States")
      base = Market.create!(name: "Tarawa", income: 1, country: "Kiribati", country_group: "Kiribati")

      subject = Fabricate(:airline, base_id: base.id)

      expect(subject.can_fly_between?(origin, destination)).to be false
      expect(subject.can_fly_between?(destination, origin)).to be false
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
