require "rails_helper"

RSpec.describe Gates do
  context "at_airport" do
    it "returns an extant gates when one exists" do
      market = Market.create!(name: "Bar", country: "Baz", country_group: "BarBaz", income: 1)
      airport = Airport.create!(start_gates: 1, easy_gates: 1, latitude: 1, longitude: 1, runway: 1, elevation: 1, iata: "Foo", market: market)
      game = Game.create!(current_date: Date.today, start_date: Date.today, end_date: Date.today)
      Gates.create!(airport: airport, game: game, current_gates: 1)
      expected_gate = Gates.last
      expected_num_slots = Slot.count

      expect(Gates.at_airport(airport, game)).to eq expected_gate
      expect(Slot.count).to eq expected_num_slots
    end

    it "creates a gates and slots when none exists" do
      market = Market.create!(name: "Bar", country: "Baz", country_group: "BarBaz", income: 1)
      airport = Airport.create!(start_gates: 1, easy_gates: 1, latitude: 1, longitude: 1, runway: 1, elevation: 1, iata: "Foo", market: market)
      game = Game.create!(current_date: Date.today, start_date: Date.today, end_date: Date.today)

      old_gates_count = Gates.count
      old_slots_count = Slot.count
      expected_new_slots = airport.start_gates * Gates::SLOTS_PER_GATE

      gates = Gates.at_airport(airport, game)

      expect(Gates.count).to eq old_gates_count + 1
      expect(Gates.last.airport).to eq airport
      expect(Gates.last.game).to eq game

      expect(Slot.count).to eq old_slots_count + expected_new_slots
      expect(Slot.last.gates_id).to eq gates.id
    end
  end

  context "airline_slots" do
    it "returns the airline's slots" do
      airport = Fabricate(:airport)
      game = Fabricate(:game)
      airline = Fabricate(:airline, game_id: game.id, base_id: airport.market_id)
      subject = Gates.create!(airport: airport, game: game, current_gates: airport.start_gates)

      expect(subject.num_slots).to eq 0
      expect(subject.airline_slots(airline).count).to eq 0

      Slot.create!(gates_id: subject.id, lessee_id: airline.id)

      expect(subject.num_slots).to eq 1
      expect(subject.airline_slots(airline).count).to eq 1

      Slot.create!(gates_id: subject.id)

      expect(subject.num_slots).to eq 2
      expect(subject.airline_slots(airline).count).to eq 1
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
        base_id: 1,
        game_id: 6,
      )
      date = Date.today
      game = Game.create!(current_date: date, start_date: date, end_date: date)
      gates = Gates.create!(airport: airport, current_gates: 1, game: game)

      old_slots = gates.slots.count
      old_cash_on_hand = airline.cash_on_hand

      expect(Calculation::SlotRent).to receive(:calculate).with(airport, game).and_return 100

      gates.build_new_gate(airline, date)
      gates.reload

      expected_slots = old_slots + Gates::SLOTS_PER_GATE

      expect(expected_slots).to eq gates.slots.count

      slot = Slot.last

      expect(slot.lessee_id).to eq airline.id
      expect(slot.lease_expiry).to eq date + Gates::NEW_SLOT_LEASE_DURATION
      expect(slot.rent).to eq 100

      airline.reload

      expect(airline.cash_on_hand).to eq old_cash_on_hand - Gates::EASY_GATE_COST

      expect(Calculation::SlotRent).to receive(:calculate).with(airport, game).and_return 150

      gates.build_new_gate(airline, date)

      airline.reload

      expect(airline.cash_on_hand).to eq old_cash_on_hand - Gates::EASY_GATE_COST - Gates::DIFFICULT_GATE_COST

      slot = Slot.last

      expect(slot.lessee_id).to eq airline.id
      expect(slot.lease_expiry).to eq date + Gates::NEW_SLOT_LEASE_DURATION
      expect(slot.rent).to eq 150
    end
  end

  context "lease_a_slot" do
    it "assigns a slot to an airline, deducts one day's rent from the airline, and sets the lease expiry" do
      game = Fabricate(:game)
      airport = Fabricate(:airport)
      original_cash_on_hand = 100000000.0
      airline = Fabricate(:airline, game_id: game.id, base_id: airport.market.id, cash_on_hand: original_cash_on_hand)
      subject = Gates.create!(airport: airport, current_gates: airport.start_gates, game: game)

      slot = Slot.create!(gates_id: subject.id)
      allow(Calculation::SlotRent).to receive(:calculate).with(airport, game).and_return original_cash_on_hand.to_f

      subject.lease_a_slot(airline)
      slot.reload
      airline.reload

      expect(slot.lessee_id).to eq airline.id
      expect(slot.rent).to be > 0
      expect(slot.lease_expiry).to eq game.current_date + Slot::LEASE_TERM_DAYS
      expect(airline.cash_on_hand).to eq original_cash_on_hand - original_cash_on_hand / Slot::LEASE_TERM_DAYS
    end

    it "adds an error if the airline does not have enough cash on hand" do
      game = Fabricate(:game)
      airport = Fabricate(:airport)
      original_cash_on_hand = 0.0
      airline = Fabricate(:airline, game_id: game.id, base_id: airport.market.id, cash_on_hand: original_cash_on_hand)
      subject = Gates.create!(airport: airport, current_gates: airport.start_gates, game: game)

      slot = Slot.create!(gates_id: subject.id)
      allow(Calculation::SlotRent).to receive(:calculate).with(airport, game).and_return 1.0

      subject.lease_a_slot(airline)
      subject.reload
      slot.reload
      airline.reload

      expect(slot.lessee_id).to be nil
      expect(slot.rent).to eq 0
      expect(slot.lease_expiry).to eq nil
      expect(subject.errors.map { |e| "#{e.attribute} #{e.message}" }).to include "airline_cash_on_hand not sufficient to lease"
      expect(airline.cash_on_hand).to eq original_cash_on_hand
    end

    it "adds an error if there are no available slots" do
      game = Fabricate(:game)
      airport = Fabricate(:airport)
      original_cash_on_hand = 1000000.0
      airline = Fabricate(:airline, game_id: game.id, base_id: airport.market.id, cash_on_hand: original_cash_on_hand)
      subject = Gates.create!(airport: airport, current_gates: airport.start_gates, game: game)

      allow(Calculation::SlotRent).to receive(:calculate).with(airport, game).and_return original_cash_on_hand.to_f

      subject.lease_a_slot(airline)
      subject.reload

      expect(subject.errors.map { |e| "#{e.attribute} #{e.message}" }).to include "slots must be available to lease"
      expect(airline.cash_on_hand).to eq original_cash_on_hand
      expect(Slot.where(lessee_id: airline.id).count).to eq 0
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

  context "num_available_slots" do
    it "includes all available slots" do
      airport = Fabricate(:airport)
      game = Fabricate(:game)
      subject = Gates.create!(airport: airport, game: game, current_gates: airport.start_gates)

      expect(subject.num_slots).to eq 0
      expect(subject.num_available_slots).to eq 0

      Slot.create!(gates_id: subject.id)

      expect(subject.num_slots).to eq 1
      expect(subject.num_available_slots).to eq 1

      Slot.create!(gates_id: subject.id, lessee_id: 3)

      expect(subject.num_slots).to eq 2
      expect(subject.num_available_slots).to eq 1
    end
  end
end
