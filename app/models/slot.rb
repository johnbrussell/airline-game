class Slot < ApplicationRecord
  validates :gates_id, presence: true

  LEASE_TERM_DAYS = 30

  scope :available, -> { where(lessee_id: nil) }

  def self.create_for_new_gates(gates_id, num)
    insert_all!([{ "gates_id": gates_id, created_at: Time.now, updated_at: Time.now }] * num)
  end
end
