class Slot < ApplicationRecord
  validates :gates_id, presence: true

  belongs_to :gates

  LEASE_TERM_DAYS = 30

  scope :available, -> { where(lessee_id: nil) }

  def self.create_for_new_gates(gates_id, num)
    insert_all!([{ "gates_id": gates_id, created_at: Time.now, updated_at: Time.now }] * num)
  end

  def self.leased(airline, airport)
    Slot
      .where(lessee_id: airline.id)
      .joins(:gates)
      .where("gates.airport_id == ?", airport.id)
  end

  def self.num_leased(airline, airport)
    Slot
      .leased(airline, airport)
      .count
  end

  def self.num_used(airline, airport)
    # Nothing on Slot indicates usage; calculate by counting frequencies on all routes to/from airport
    AirlineRoute
      .where(airline_id: airline.id)
      .where(origin_airport_id: airport.id)
      .or(AirlineRoute.where(airline_id: airline.id).where(destination_airport_id: airport.id))
      .joins(:airplane_routes)
      .sum("airplane_routes.frequencies")
  end

  def self.percent_used(airline, airport)
    self.num_used(airline, airport) / self.num_leased(airline, airport).to_f * 100
  end

  def return
    update(
      rent: 0,
      lessee_id: nil,
      lease_expiry: nil,
    )
  end
end
