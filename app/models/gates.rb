class Gates < ApplicationRecord
  validates :airport_id, presence: true
  validates :game_id, presence: true
  validates :current_gates, presence: true
  validate :current_gates_greater_than_start_gates

  belongs_to :airport
  belongs_to :game
  has_many :slots

  SLOTS_PER_GATE = 70
  NEW_SLOT_LEASE_DURATION = 3.years

  def build_new_gate(airline, current_date)
    Slot.insert_all!([
      {
      "gates_id": id,
      "lessee_id": airline.id,
      "lease_expiry": current_date + NEW_SLOT_LEASE_DURATION,
      "created_at": Time.now,
      "updated_at": Time.now,
      }
    ] * SLOTS_PER_GATE)
    update!(current_gates: current_gates + 1)
  end

  private

    def current_gates_greater_than_start_gates
      if current_gates < airport.start_gates
        errors.add(:current_gates, "cannot be less than minimum gates at airport")
      end
    end
end
