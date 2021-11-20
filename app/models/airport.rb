class Airport < ApplicationRecord
  belongs_to :market

  validates :iata, presence: true
  validates :exclusive_catchment, presence: true
  validates :exclusive_catchment, numericality: { greater_than_or_equal_to: 0, less_than: 100 }
  validates :runway, presence: true
  validates :runway, numericality: { greater_than: 0 }
  validates :elevation, presence: true
  validates :elevation, numericality: { greater_than: -1411, less_than: 29032 }
  validates :start_gates, presence: true
  validates :start_gates, numericality: { greater_than_or_equal_to: 1 }
  validates :easy_gates, presence: true
  validates :easy_gates, numericality: { greater_than_or_equal_to: :start_gates }
  validates :current_gates, presence: true
  validates :current_gates, numericality: { greater_than_or_equal_to: :start_gates }
  validates :latitude, presence: true
  validates :latitude, numericality: { greater_than: -90, less_than: 90 }
  validates :longitude, presence: true
  validates :longitude, numericality: { greater_than: -180, less_than: 180 }

  validates_uniqueness_of :iata

  has_many :global_demands
  has_many :slots

  SLOTS_PER_GATE = 70
  NEW_SLOT_LEASE_DURATION = 3.years

  def build_new_gate(airline, current_date)
    Slot.insert_all!([
      {
      "airport_id": id,
      "lessee_id": airline.id,
      "lease_expiry": current_date + NEW_SLOT_LEASE_DURATION,
      "created_at": Time.now,
      "updated_at": Time.now,
      }
    ] * SLOTS_PER_GATE)
    update!(current_gates: current_gates + 1)
  end
end
