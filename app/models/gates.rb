class Gates < ApplicationRecord
  validates :airport_id, presence: true
  validates :game_id, presence: true
  validates :current_gates, presence: true
  validate :current_gates_greater_than_start_gates

  belongs_to :airport
  belongs_to :game

  private

    def current_gates_greater_than_start_gates
      if current_gates < airport.start_gates
        errors.add(:current_gates, "cannot be less than minimum gates at airport")
      end
    end
end
