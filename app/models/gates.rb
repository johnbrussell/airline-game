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
  USE_IT_OR_LOSE_IT_THRESHOLD = 0.8

  def self.at_airport(airport, game)
    if find_by(airport: airport, game: game).present?
      find_by(airport: airport, game: game)
    else
      create!(airport: airport, game: game, current_gates: airport.start_gates).tap do |gates|
        Slot.create_for_new_gates(gates.id, SLOTS_PER_GATE * airport.start_gates)
      end
    end
  end

  def airline_slots(airline)
    slots.where(lessee_id: airline.id)
  end

  def build_new_gate(airline, current_date)
    if RivalCountryGroup.rivals?(airline.base.country_group, airport.market.country_group)
      errors.add(:airline, "cannot build gates due to political restrictions")
    elsif airline.cash_on_hand >= gate_cost
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
    else
      errors.add(:airline_cash_on_hand, "not sufficient to build")
    end
  end

  def gate_cost
    current_gates < airport.easy_gates ? EASY_GATE_COST : DIFFICULT_GATE_COST
  end

  def lease_a_slot(airline)
    if RivalCountryGroup.rivals?(airline.base.country_group, airport.market.country_group)
      errors.add(:airline, "cannot lease slots due to political restrictions")
    elsif num_available_slots > 0
      rent = Calculation::SlotRent.calculate(airport, game) / Slot::LEASE_TERM_DAYS # Calculation::SlotRent assumes term is Slot::LEASE_TERM_DAYS
      slot = slots.available.first
      slot.assign_attributes(
        lessee_id: airline.id,
        lease_expiry: game.current_date + lease_term(airline).days,
        rent: rent,
      )
      if airline.cash_on_hand >= rent
        slot.save
        airline.update!(cash_on_hand: airline.cash_on_hand - rent)
      else
        errors.add(:airline_cash_on_hand, "not sufficient to lease")
      end
    else
      errors.add(:slots, "must be available to lease")
    end
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

    def is_above_use_it_or_lose_it_threshold(airline)
      (Slot.num_leased(airline, airport) * USE_IT_OR_LOSE_IT_THRESHOLD).floor() >= Slot.num_used(airline, airport)
    end

    def lease_term(airline)
      if is_above_use_it_or_lose_it_threshold(airline)
        1
      else
        Slot::LEASE_TERM_DAYS
      end
    end
end
