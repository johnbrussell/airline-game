require "rails_helper"

RSpec.describe Gates do
  context "at_airport" do
    it "returns an extant gates when one exists" do
      market = Market.create!(name: "Bar", country: "Baz", country_group: "BarBaz", income: 1)
      airport = Airport.create!(start_gates: 1, easy_gates: 1, latitude: 1, longitude: 1, runway: 1, elevation: 1, iata: "Foo", market: market)
      game = Game.create!(current_date: Date.today, start_date: Date.today, end_date: Date.today)
      Gates.create!(airport: airport, game: game, current_gates: 1)
      expected_gate = Gates.last

      expect(Gates.at_airport(airport, game)).to eq expected_gate
    end

    it "creates a gates when none exists" do
      market = Market.create!(name: "Bar", country: "Baz", country_group: "BarBaz", income: 1)
      airport = Airport.create!(start_gates: 1, easy_gates: 1, latitude: 1, longitude: 1, runway: 1, elevation: 1, iata: "Foo", market: market)
      game = Game.create!(current_date: Date.today, start_date: Date.today, end_date: Date.today)

      old_gates_count = Gates.count

      gates = Gates.at_airport(airport, game)

      expect(Gates.count).to eq old_gates_count + 1
      expect(Gates.last.airport).to eq airport
      expect(Gates.last.game).to eq game
    end
  end

  context "build_new_gate" do
    it "creates new slots for the appropriate airline and updates the number of gates on the Airport and charges the airline" do
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
        easy_gates: 2,
        latitude: 40,
        longitude: -70,
        market: Market.last,
      )
      airline = Airline.create!(
        name: "Foo",
        cash_on_hand: 1000000000,
        is_user_airline: false,
      )
      date = Date.today
      game = Game.create!(current_date: date, start_date: date, end_date: date)
      gates = Gates.create!(airport: airport, current_gates: 1, game: game)

      old_slots = gates.slots.count
      old_cash_on_hand = airline.cash_on_hand

      gates.build_new_gate(airline, date)
      gates.reload

      expected_slots = old_slots + Gates::SLOTS_PER_GATE

      expect(expected_slots).to eq gates.slots.count

      slot = Slot.last

      expect(slot.lessee_id).to eq airline.id
      expect(slot.lease_expiry).to eq date + Gates::NEW_SLOT_LEASE_DURATION

      airline.reload

      expect(airline.cash_on_hand).to eq old_cash_on_hand - Gates::EASY_GATE_COST

      gates.build_new_gate(airline, date)

      airline.reload

      expect(airline.cash_on_hand).to eq old_cash_on_hand - Gates::EASY_GATE_COST - Gates::DIFFICULT_GATE_COST
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
