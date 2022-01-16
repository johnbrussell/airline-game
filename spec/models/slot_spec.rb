require "rails_helper"

RSpec.describe Slot do
  context "create_for_new_gates" do
    before(:each) do
      game = Fabricate(:game)
      airport = Fabricate(:airport)
      Gates.create!(game: game, airport: airport, current_gates: airport.start_gates)
    end

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
end
