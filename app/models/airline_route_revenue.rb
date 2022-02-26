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

  belongs_to :airline_route

  private

    def revenue_calculated_correctly
      pax_revenue = airline_route.economy_price * economy_pax + airline_route.premium_economy_price * premium_economy_pax + airline_route.business_price * business_pax
      if pax_revenue.round(2) != revenue
        errors.add(:revenue, "not calculated correctly")
      end
    end
end
