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
  EASY_GATE_COST = 10000000
  DIFFICULT_GATE_COST = 100000000

  def self.at_airport(airport, game)
    if find_by(airport: airport, game: game).present?
      find_by(airport: airport, game: game)
    else
      create!(airport: airport, game: game, current_gates: airport.start_gates)
    end
  end

  def build_new_gate(airline, current_date)
    Slot.insert_all!([
      {
        "gates_id": id,
        "lessee_id": airline.id,
        "lease_expiry": current_date + NEW_SLOT_LEASE_DURATION,
        "rent": Calculation::SlotRent.calculate(airport, game),
        "created_at": Time.now,
        "updated_at": Time.now,
      }
    ] * SLOTS_PER_GATE)
    airline.update!(cash_on_hand: airline.cash_on_hand - gate_cost)
    update!(current_gates: current_gates + 1)
  end

  def num_slots
    slots.count
  end

  def num_available_slots
    slots.available.count
  end

  private

    def current_gates_greater_than_start_gates
      if current_gates < airport.start_gates
        errors.add(:current_gates, "cannot be less than minimum gates at airport")
      end
    end

    def gate_cost
      current_gates < airport.easy_gates ? EASY_GATE_COST : DIFFICULT_GATE_COST
    end
end
