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
  validates :latitude, presence: true
  validates :latitude, numericality: { greater_than: -90, less_than: 90 }
  validates :longitude, presence: true
  validates :longitude, numericality: { greater_than: -180, less_than: 180 }

  validates_uniqueness_of :iata

  has_many :global_demands

  def self.select_options
    all.order(:iata).map do |airport|
      ["#{airport.iata} - #{airport.display_name}, #{airport.market.country}", airport.id]
    end
  end

  def self.with_slots(airline)
    Airport
      .joins("INNER JOIN gates ON gates.airport_id == airports.id")
      .joins("INNER JOIN slots ON slots.gates_id == gates.id")
      .where("slots.lessee_id == ?", airline.id)
      .order(:iata)
      .uniq
  end

  def display_name
    municipality || market.name
  end

  def is_on_island?
    market.is_island
  end

  def leased_unused_slots(airline)
    Slot.num_leased(airline, self) - Slot.num_used(airline, self)
  end

  def other_market_airports
    market.airports.reject{ |airport| airport.iata == iata }
  end

  def slot_expenditures(airline)
    Slot.leased(airline, self).sum(&:rent)
  end
end
