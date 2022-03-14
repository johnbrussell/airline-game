require "rails_helper"

RSpec.describe Slot do
  before(:each) do
    game = Fabricate(:game)
    market = Fabricate(:market, name: "Default")
    airport = Fabricate(:airport, iata: "BOS", market: market)
    Gates.create!(game: game, airport: airport, current_gates: airport.start_gates)
  end

  context "create_for_new_gates" do
    it "creates new slots creates the requested number of slots" do
      num_slots = Slot.count
      slots_to_create = 3
      gates = Gates.last

      Slot.create_for_new_gates(gates.id, slots_to_create)

      new_num_slots = Slot.count

      expect(new_num_slots).to eq num_slots + slots_to_create
      expect(Slot.last.gates_id).to eq gates.id
    end
  end

  context "num_leased" do
    it "is zero when no slots are leased at the airport" do
      airline = Fabricate(:airline, game_id: Game.last.id, base_id: Airport.last.market.id)

      expect(Slot.num_leased(airline, Airport.last)).to eq 0
    end

    it "accurately counts the number of slots leased" do
      airline = Fabricate(:airline, game_id: Game.last.id, base_id: Airport.last.market.id)

      Slot.create!(gates_id: Gates.last.id, lessee_id: airline.id)

      expect(Slot.num_leased(airline, Airport.last)).to eq 1
    end
  end

  context "num_used" do
    it "is zero when no slots are used at the airport" do
      airline = Fabricate(:airline, game_id: Game.last.id, base_id: Airport.last.market.id)

      expect(Slot.num_used(airline, Airport.last)).to eq 0
    end

    it "accurately counts the number of slots used" do
      airline = Fabricate(:airline, game_id: Game.last.id, base_id: Airport.last.market.id)
      other_airline = Fabricate(:airline, game_id: Game.last.id, base_id: Airport.last.market.id)

      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, market: inu.market, iata: "FUN")
      maj = Fabricate(:airport, market: inu.market, iata: "MAJ")

      family = Fabricate(:aircraft_family)
      airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)
      other_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: other_airline.id, base_country_group: other_airline.base.country_group)

      AirlineRoute.new(airline: airline, origin_airport: fun, destination_airport: inu, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 1).save(validate: false)
      fun_inu = AirlineRoute.last
      AirlineRoute.new(airline: airline, origin_airport: inu, destination_airport: maj, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 1).save(validate: false)
      inu_maj = AirlineRoute.last
      AirplaneRoute.new(airplane: airplane, route: fun_inu, frequencies: 3, block_time_mins: 1, flight_cost: 3).save(validate: false)
      AirplaneRoute.new(airplane: airplane, route: inu_maj, frequencies: 1, block_time_mins: 1, flight_cost: 3).save(validate: false)

      AirlineRoute.new(airline: other_airline, origin_airport: fun, destination_airport: maj, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 1).save(validate: false)
      fun_maj = AirlineRoute.last
      AirplaneRoute.new(airplane: other_airplane, route: fun_maj, frequencies: 5, block_time_mins: 1, flight_cost: 2).save(validate: false)

      expect(Slot.num_used(airline, inu)).to eq 4
      expect(Slot.num_used(airline, fun)).to eq 3
      expect(Slot.num_used(airline, maj)).to eq 1
    end
  end

  context "percent used" do
    it "accurately calculates the percentage of slots that are used" do
      airline = Fabricate(:airline, game_id: Game.last.id, base_id: Airport.last.market.id)
      other_airline = Fabricate(:airline, game_id: Game.last.id, base_id: Airport.last.market.id)

      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, market: inu.market, iata: "FUN")
      maj = Fabricate(:airport, market: inu.market, iata: "MAJ")

      family = Fabricate(:aircraft_family)
      airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)
      other_airplane = Fabricate(:airplane, aircraft_family: family, operator_id: other_airline.id, base_country_group: other_airline.base.country_group)

      AirlineRoute.new(airline: airline, origin_airport: fun, destination_airport: inu, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 1).save(validate: false)
      fun_inu = AirlineRoute.last
      AirlineRoute.new(airline: airline, origin_airport: inu, destination_airport: maj, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 1).save(validate: false)
      inu_maj = AirlineRoute.last
      AirplaneRoute.new(airplane: airplane, route: fun_inu, frequencies: 3, block_time_mins: 1, flight_cost: 3).save(validate: false)
      AirplaneRoute.new(airplane: airplane, route: inu_maj, frequencies: 1, block_time_mins: 1, flight_cost: 3).save(validate: false)

      AirlineRoute.new(airline: other_airline, origin_airport: fun, destination_airport: maj, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 1).save(validate: false)
      fun_maj = AirlineRoute.last
      AirplaneRoute.new(airplane: other_airplane, route: fun_maj, frequencies: 5, block_time_mins: 1, flight_cost: 2).save(validate: false)

      inu_gates = Gates.create!(airport: inu, current_gates: 5, game: Game.find(airline.game_id))
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      fun_gates = Gates.create!(airport: fun, current_gates: 5, game: Game.find(airline.game_id))
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      maj_gates = Gates.create!(airport: maj, current_gates: 5, game: Game.find(airline.game_id))
      Slot.create!(gates: maj_gates, lessee_id: airline.id)
      Slot.create!(gates: maj_gates, lessee_id: airline.id)
      Slot.create!(gates: maj_gates, lessee_id: airline.id)

      expect(Slot.num_leased(airline, inu)).to eq 4
      expect(Slot.num_leased(airline, fun)).to eq 4
      expect(Slot.num_leased(airline, maj)).to eq 3

      expect(Slot.num_used(airline, inu)).to eq 4
      expect(Slot.num_used(airline, fun)).to eq 3
      expect(Slot.num_used(airline, maj)).to eq 1

      expect(Slot.percent_used(airline, inu)).to eq 100
      expect(Slot.percent_used(airline, fun)).to eq 75
      assert_in_epsilon Slot.percent_used(airline, maj), 100 / 3.0, 0.000001
    end
  end

  context "return" do
    it "sets the rent, lease expiry, and lessee to nil" do
      airline = Fabricate(:airline, game_id: Game.last.id, base_id: Airport.last.market.id)

      subject = Slot.create!(gates_id: Gates.last.id, lessee_id: airline.id, lease_expiry: Date.today, rent: 1)

      expect(subject.return).to be true

      subject.reload

      expect(subject.lessee_id).to be nil
      expect(subject.rent).to eq 0
      expect(subject.lease_expiry).to be nil
      expect(subject.gates_id).to eq Gates.last.id
    end
  end
end
