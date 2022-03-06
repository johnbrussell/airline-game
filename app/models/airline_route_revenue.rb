class AirlineRouteRevenue < ApplicationRecord
  validates :airline_route_id, presence: true
  validates :economy_pax, presence: true
  validates :economy_pax, numericality: { greater_than_or_equal_to: 0 }
  validates :premium_economy_pax, presence: true
  validates :premium_economy_pax, numericality: { greater_than_or_equal_to: 0 }
  validates :business_pax, presence: true
  validates :business_pax, numericality: { greater_than_or_equal_to: 0 }
  validates :revenue, presence: true
  validates :revenue, numericality: { greater_than_or_equal_to: 0 }
  validate :revenue_calculated_correctly
  validate :enough_seating_for_passengers

  belongs_to :airline_route

  def zero_out
    update(
      economy_pax: 0,
      premium_economy_pax: 0,
      business_pax: 0,
      revenue: 0,
    )
  end

  private

    def enough_seating_for_passengers
      if airline_route.total_economy_seats < economy_pax || airline_route.total_premium_economy_seats < premium_economy_pax || airline_route.total_business_seats < business_pax
        errors.add(:seats, "not sufficient to seat passengers")
      end
    end

    def revenue_calculated_correctly
      pax_revenue = airline_route.economy_price * economy_pax + airline_route.premium_economy_price * premium_economy_pax + airline_route.business_price * business_pax
      if (pax_revenue.round(2) - revenue.to_f).round(2).abs > 0.011
        errors.add(:revenue, "not calculated correctly.  Expected #{revenue}, got #{pax_revenue}.  Difference #{(pax_revenue.round(2) - revenue).round(2).abs}")
      end
    end
end
