class Slot < ApplicationRecord
  validates :gates_id, presence: true

  scope :available, -> { where(lessee_id: nil) }
end
