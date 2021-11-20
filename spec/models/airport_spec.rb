require "rails_helper"

RSpec.describe Airport do
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

      old_slots = airport.slots.count

      airport.build_new_gate(airline, date)
      airport.reload

      expected_slots = old_slots + Airport::SLOTS_PER_GATE

      assert expected_slots == airport.slots.count

      slot = Slot.last

      assert slot.lessee_id == airline.id
      assert slot.lease_expiry == date + Airport::NEW_SLOT_LEASE_DURATION
    end
  end
end
