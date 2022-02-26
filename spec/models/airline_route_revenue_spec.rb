require "rails_helper"

RSpec.describe AirlineRouteRevenue do
  context "valid?" do
    let(:origin_airport) { Fabricate(:airport, iata: "KWA") }
    let(:destination_airport) { Fabricate(:airport, market: origin_airport.market, iata: "MAJ") }
    let(:airline) { Fabricate(:airline, base_id: origin_airport.market.id) }
    let(:airline_route) { AirlineRoute.create!(origin_airport: origin_airport, destination_airport: destination_airport, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline, distance: 1) }

    it "is true when revenue is calculated correctly" do
      subject = AirlineRouteRevenue.new(revenue: 174, economy_pax: 138, premium_economy_pax: 12, business_pax: 4, airline_route: airline_route)

      expect(subject.valid?).to be true
    end

    it "is false when revenue is not calculated correctly" do
      subject = AirlineRouteRevenue.new(revenue: 174, economy_pax: 138.1, premium_economy_pax: 11.9, business_pax: 4, airline_route: airline_route)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Revenue not calculated correctly"
    end
  end
end
