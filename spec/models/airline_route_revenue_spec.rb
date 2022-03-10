require "rails_helper"

RSpec.describe AirlineRouteRevenue do
  context "valid?" do
    let(:origin_airport) { Fabricate(:airport, iata: "KWA") }
    let(:destination_airport) { Fabricate(:airport, market: origin_airport.market, iata: "MAJ") }
    let(:airline) { Fabricate(:airline, base_id: origin_airport.market.id) }
    let(:airline_route) { AirlineRoute.create!(origin_airport: origin_airport, destination_airport: destination_airport, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline, distance: 1) }

    before(:each) do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: 100000)
      airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: origin_airport.market.country_group, aircraft_model: model, economy_seats: 138, premium_economy_seats: 12, business_seats: 4)
      AirplaneRoute.new(airplane: airplane, route: airline_route, flight_cost: 1, block_time_mins: 1, frequencies: 1).save(validate: false)
    end

    it "is true when revenue is calculated correctly and the seats are calculated correctly" do
      subject = AirlineRouteRevenue.new(revenue: 174 * 2, exclusive_revenue: 1, economy_pax: 138, premium_economy_pax: 12, business_pax: 4, airline_route: airline_route)

      expect(subject.valid?).to be true
    end

    it "is false when revenue is not calculated correctly" do
      subject = AirlineRouteRevenue.new(revenue: 174 * 2, exclusive_revenue: 1, economy_pax: 138.1, premium_economy_pax: 11.9, business_pax: 4, airline_route: airline_route)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Revenue not calculated correctly.  Expected 348.0, got 347.8.  Difference 0.2"
    end

    it "is false when seats are not sufficient for economy passengers" do
      subject = AirlineRouteRevenue.new(revenue: 174, exclusive_revenue: 1, economy_pax: 138.1, premium_economy_pax: 11.9, business_pax: 4, airline_route: airline_route)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Seats not sufficient to seat passengers"
    end

    it "is false when seats are not sufficient for premium economy passengers" do
      subject = AirlineRouteRevenue.new(revenue: 174, exclusive_revenue: 1, economy_pax: 138, premium_economy_pax: 12.1, business_pax: 4, airline_route: airline_route)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Seats not sufficient to seat passengers"
    end

    it "is false when seats are not sufficient for business passengers" do
      subject = AirlineRouteRevenue.new(revenue: 174, exclusive_revenue: 1, economy_pax: 138, premium_economy_pax: 12, business_pax: 4.1, airline_route: airline_route)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Seats not sufficient to seat passengers"
    end
  end

  context "zero_out" do
    let(:origin_airport) { Fabricate(:airport, iata: "KWA") }
    let(:destination_airport) { Fabricate(:airport, market: origin_airport.market, iata: "MAJ") }
    let(:airline) { Fabricate(:airline, base_id: origin_airport.market.id) }
    let(:airline_route) { AirlineRoute.create!(origin_airport: origin_airport, destination_airport: destination_airport, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: airline, distance: 1) }

    it "sets revenue and passengers to zero" do
      AirlineRouteRevenue.new(revenue: 174, exclusive_revenue: 174, economy_pax: 138, premium_economy_pax: 12, business_pax: 4, airline_route: airline_route).save(validate: false)
      subject = AirlineRouteRevenue.last

      expect(subject.zero_out).to be true
      subject.reload

      expect(subject.revenue).to eq 0
      expect(subject.exclusive_revenue).to eq 0
      expect(subject.business_pax).to eq 0
      expect(subject.premium_economy_pax).to eq 0
      expect(subject.economy_pax).to eq 0
    end
  end
end
