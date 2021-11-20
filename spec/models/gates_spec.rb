require "rails_helper"

RSpec.describe Gates do
  context "build_new_gate" do
    it "creates new slots for the appropriate airline and updates the number of gates on the Airport" do
      Market.create!(
        name: "Bar",
        country: "Baz",
        country_group: "Foobar",
        income: 1,
      )
      airport = Airport.create!(
        iata: "DCA",
        exclusive_catchment: 0,
        runway: 1000,
        elevation: 10,
        start_gates: 1,
        current_gates: 1,
        easy_gates: 1,
        latitude: 40,
        longitude: -70,
        market: Market.last,
      )
      airline = Airline.create!(
        name: "Foo",
        cash_on_hand: 100,
        is_user_airline: false,
      )
      date = Date.today
      game = Game.create!(current_date: date, start_date: date, end_date: date)
      gates = Gates.create!(airport: airport, current_gates: 1, game: game)

      old_slots = gates.slots.count

      gates.build_new_gate(airline, date)
      gates.reload

      expected_slots = old_slots + Gates::SLOTS_PER_GATE

      assert expected_slots == gates.slots.count

      slot = Slot.last

      assert slot.lessee_id == airline.id
      assert slot.lease_expiry == date + Gates::NEW_SLOT_LEASE_DURATION
    end
  end

  context "validate current_gates_greater_than_start_gates" do
    before(:each) do
      market = Market.create!(
        name: "City",
        country: "County",
        country_group: "Country",
        income: 1,
      )
      Airport.create!(
        iata: "ABC",
        exclusive_catchment: 0,
        runway: 1000,
        elevation: 1000,
        start_gates: 2,
        current_gates: 3,
        easy_gates: 2,
        latitude: 40,
        longitude: 40,
        market: market,
      )
      Game.create!(
        start_date: Date.yesterday,
        end_date: Date.tomorrow,
        current_date: Date.today,
      )
    end

    it "fails if current_gates is less than the airport's start_gates" do
      airport = Airport.last
      game = Game.last
      subject = Gates.new(airport: airport, game: game, current_gates: 1)

      expect(subject.validate).to be false
      expect(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include "current_gates cannot be less than minimum gates at airport"
    end

    it "passes if current_gates is equal to the airport's start_gates" do
      airport = Airport.last
      game = Game.last
      subject = Gates.new(airport: airport, game: game, current_gates: 2)

      expect subject.validate
    end

    it "passes if current_gates is greater than the airport's start_gates" do
      airport = Airport.last
      game = Game.last
      subject = Gates.new(airport: airport, game: game, current_gates: 3)

      expect subject.validate
    end
  end
end
