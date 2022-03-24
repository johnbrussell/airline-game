require "rails_helper"

RSpec.describe Airport do
  context "display name" do
    it "shows the municipality name if it is present" do
      subject = Fabricate(:airport, municipality: "Somerville")

      expect(subject.display_name).to eq "Somerville"
    end

    it "is the market name if it is not present" do
      market = Fabricate(:market, name: "Somerville")
      subject = Fabricate(:airport, municipality: nil, market: market)

      expect(subject.display_name).to eq "Somerville"
    end
  end

  context "leased_unused_slots" do
    it "calculates correctly" do
      airline = Fabricate(:airline)
      subject = Fabricate(:airport, market: airline.base)

      expect(Slot).to receive(:num_leased).with(airline, subject).and_return(5)
      expect(Slot).to receive(:num_used).with(airline, subject).and_return(1)

      expect(subject.leased_unused_slots(airline)).to eq 4
    end
  end

  context "other_market_airports" do
    before(:each) do
      boston = Fabricate(
        :market, 
        name: "Boston",
        country: "United States",
        country_group: "United States",
        income: 100,
      )
      Airport.create!(iata: "BOS", market: boston, runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 1, longitude: 1)
    end

    it "is an empty array when there are no other airports in the market" do
      subject = Airport.last

      expect(subject.other_market_airports.empty?).to eq true
    end

    it "includes the other airports in the market when there are other airports in the market" do
      subject = Airport.create!(iata: "MHT", market: Market.last, runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 10, longitude: 1)

      expect(subject.other_market_airports.empty?).to eq false
      expect(subject.other_market_airports.length).to eq 1
      expect(subject.other_market_airports.first.iata).to eq "BOS"
    end
  end

  context "slot_expenditures" do
    it "calculates correctly" do
      game = Fabricate(:game)
      airport = Fabricate(:airport)
      other_airport = Fabricate(:airport, market: airport.market, iata: "GBR")
      airline = Fabricate(:airline, base_id: airport.market.id)
      gates = Gates.create!(airport: airport, current_gates: airport.start_gates, game: game)
      Slot.create!(gates: gates, lessee_id: airline.id, rent: 1)

      airport.reload
      other_airport.reload

      expect(airport.slot_expenditures(airline)).to eq 1
      expect(other_airport.slot_expenditures(airline)).to eq 0

      Slot.create!(gates: gates, lessee_id: airline.id, rent: 1000)

      airport.reload

      expect(airport.slot_expenditures(airline)).to eq 1001
    end
  end

  context "with_slots" do
    it "returns airports with slots for the specified airline" do
      airline_1 = Fabricate(:airline)
      airline_2 = Fabricate(:airline, name: "Different", base_id: airline_1.base.id)

      bos = Fabricate(:airport, iata: "BOS", market: airline_1.base, municipality: "Boston")
      sfo = Fabricate(:airport, iata: "SFO", market: airline_1.base, municipality: "San Francisco")

      bos_gates = Gates.create!(airport_id: bos.id, current_gates: 5, game_id: airline_1.game_id)
      sfo_gates = Gates.create!(airport_id: sfo.id, current_gates: 5, game_id: airline_1.game_id)

      Slot.create!(lessee_id: airline_1.id, gates: sfo_gates)
      Slot.create!(lessee_id: airline_1.id, gates: sfo_gates)
      Slot.create!(lessee_id: airline_1.id, gates: bos_gates)
      Slot.create!(lessee_id: airline_2.id, gates: sfo_gates)

      expect(Airport.with_slots(airline_1)).to eq [bos, sfo]
      expect(Airport.with_slots(airline_2)).to eq [sfo]
    end
  end
end
