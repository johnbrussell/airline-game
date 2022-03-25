require "rails_helper"

RSpec.describe Calculation::InertiaRouteService do
  context "frequencies and fares that evaluate to integers" do
    let(:origin) { instance_double(Airport, market: instance_double(Market, country_group: "Foo")) }
    let(:destination) { instance_double(Airport, market: instance_double(Market)) }
    let(:date) { Date.today }
    let(:flight_cost) { 17442 }
    let(:flight_cost_calculator) { instance_double(Calculation::FlightCostCalculator, cost: flight_cost) }
    let(:business_revenue) { 36720 * 2 }
    let(:economy_revenue) { 107100 * 2 }
    let(:premium_economy_revenue) { 30600 * 2 }
    let(:revenue) {
      instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_revenue,
        max_economy_class_revenue_per_week: economy_revenue,
        max_premium_economy_class_revenue_per_week: premium_economy_revenue,
      )
    }
    let(:distance) { Calculation::InertiaRouteService::LONG_DISTANCE }
    let(:subject) { Calculation::InertiaRouteService.new(origin, destination, date) }

    before(:each) do
      allow(Calculation::MaximumRevenuePotential).to receive(:new).with(origin, destination, date).and_return(revenue)
      allow(Calculation::FlightCostCalculator).to receive(:new).and_return(flight_cost_calculator)
      allow(Calculation::Distance).to receive(:between_airports).and_return(distance)
      allow(Calculation::Distance).to receive(:between_markets).and_return(distance)
    end

    it "calculates frequencies correctly" do
      other_revenue = instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: 36720,
        max_economy_class_revenue_per_week: 107100,
        max_premium_economy_class_revenue_per_week: 30600,
      )
      allow(Calculation::MaximumRevenuePotential).to receive(:new).with(origin, destination, date).and_return(other_revenue)

      expect(subject.send(:desired_business_frequencies)).to eq 2.5
      expect(subject.business_frequencies).to eq 3

      expect(subject.send(:desired_economy_frequencies)).to eq 2.5
      expect(subject.economy_frequencies).to eq 3

      expect(subject.send(:desired_premium_economy_frequencies)).to eq 2.5
      expect(subject.premium_economy_frequencies).to eq 3
    end

    it "calculates fares correctly" do
      expect(subject.send(:business_revenue)).to eq business_revenue * Calculation::InertiaRouteService::REVENUE_PERCENTAGE / 2.0
      assert_in_epsilon subject.business_fare, subject.send(:business_revenue) / Calculation::InertiaRouteService::LONG_DISTANCE_BUSINESS_SEATS / 5 * Calculation::InertiaRouteService::MANAGEMENT_OVERHEAD, 0.000001

      expect(subject.send(:business_flight_cost)).to be <= subject.business_fare * subject.business_seats_per_flight

      expect(subject.send(:economy_revenue)).to eq economy_revenue * Calculation::InertiaRouteService::REVENUE_PERCENTAGE / 2.0
      assert_in_epsilon subject.economy_fare, subject.send(:economy_revenue) / Calculation::InertiaRouteService::LONG_DISTANCE_ECONOMY_SEATS / 5 * Calculation::InertiaRouteService::MANAGEMENT_OVERHEAD, 0.000001

      expect(subject.send(:economy_flight_cost)).to be <= subject.economy_fare * subject.economy_seats_per_flight

      expect(subject.send(:premium_economy_revenue)).to eq premium_economy_revenue * Calculation::InertiaRouteService::REVENUE_PERCENTAGE / 2.0
      assert_in_epsilon subject.premium_economy_fare, subject.send(:premium_economy_revenue) / Calculation::InertiaRouteService::LONG_DISTANCE_PREMIUM_ECONOMY_SEATS / 5 * Calculation::InertiaRouteService::MANAGEMENT_OVERHEAD, 0.000001

      expect(subject.send(:premium_economy_flight_cost)).to be <= subject.premium_economy_fare * subject.premium_economy_seats_per_flight
    end
  end

  context "frequencies and fares that do not evaluate to integers" do
    let(:origin) { instance_double(Airport, market: instance_double(Market, country_group: "Foo")) }
    let(:destination) { instance_double(Airport, market: instance_double(Market)) }
    let(:date) { Date.today }
    let(:flight_cost) { 17442 }
    let(:flight_cost_calculator) { instance_double(Calculation::FlightCostCalculator, cost: flight_cost) }
    let(:business_revenue) { 36700 * 2 }
    let(:economy_revenue) { 107000 * 2 }
    let(:premium_economy_revenue) { 30000 * 2 }
    let(:revenue) {
      instance_double(
        Calculation::MaximumRevenuePotential,
        max_business_class_revenue_per_week: business_revenue,
        max_economy_class_revenue_per_week: economy_revenue,
        max_premium_economy_class_revenue_per_week: premium_economy_revenue,
      )
    }
    let(:distance) { Calculation::InertiaRouteService::LONG_DISTANCE }
    let(:subject) { Calculation::InertiaRouteService.new(origin, destination, date) }

    before(:each) do
      allow(Calculation::MaximumRevenuePotential).to receive(:new).with(origin, destination, date).and_return(revenue)
      allow(Calculation::Distance).to receive(:between_markets).and_return(distance)
    end

    it "calculates frequencies correctly" do
      allow(Calculation::FlightCostCalculator).to receive(:new).and_return(flight_cost_calculator)
      allow(Calculation::Distance).to receive(:between_airports).and_return(distance)

      expect(subject.send(:desired_business_frequencies)).to be > 4
      expect(subject.send(:desired_business_frequencies)).to be < 5
      expect(subject.business_frequencies).to eq 5

      expect(subject.send(:desired_economy_frequencies)).to be > 4
      expect(subject.send(:desired_economy_frequencies)).to be < 5
      expect(subject.economy_frequencies).to eq 5

      expect(subject.send(:desired_premium_economy_frequencies)).to be > 4
      expect(subject.send(:desired_premium_economy_frequencies)).to be < 5
      expect(subject.premium_economy_frequencies).to eq 5
    end

    it "calculates fares correctly" do
      allow(Calculation::FlightCostCalculator).to receive(:new).and_return(flight_cost_calculator)
      allow(Calculation::Distance).to receive(:between_airports).and_return(distance)

      expect(subject.send(:business_revenue)).to eq business_revenue * Calculation::InertiaRouteService::REVENUE_PERCENTAGE / 2.0
      expect(subject.business_fare).to be > subject.send(:business_revenue) / Calculation::InertiaRouteService::LONG_DISTANCE_BUSINESS_SEATS / 5 * Calculation::InertiaRouteService::MANAGEMENT_OVERHEAD
      expect(subject.business_fare).to be < subject.send(:business_revenue) / Calculation::InertiaRouteService::LONG_DISTANCE_BUSINESS_SEATS / 4 * Calculation::InertiaRouteService::MANAGEMENT_OVERHEAD

      expect(subject.send(:business_flight_cost)).to be <= subject.business_fare * subject.business_seats_per_flight

      expect(subject.send(:economy_revenue)).to eq economy_revenue * Calculation::InertiaRouteService::REVENUE_PERCENTAGE / 2.0
      expect(subject.economy_fare).to be > subject.send(:economy_revenue) / Calculation::InertiaRouteService::LONG_DISTANCE_ECONOMY_SEATS / 5 * Calculation::InertiaRouteService::MANAGEMENT_OVERHEAD
      expect(subject.economy_fare).to be < subject.send(:economy_revenue) / Calculation::InertiaRouteService::LONG_DISTANCE_ECONOMY_SEATS / 4 * Calculation::InertiaRouteService::MANAGEMENT_OVERHEAD

      expect(subject.send(:economy_flight_cost)).to be <= subject.economy_fare * subject.economy_seats_per_flight

      expect(subject.send(:premium_economy_revenue)).to eq premium_economy_revenue * Calculation::InertiaRouteService::REVENUE_PERCENTAGE / 2.0
      expect(subject.premium_economy_fare).to be > subject.send(:premium_economy_revenue) / Calculation::InertiaRouteService::LONG_DISTANCE_PREMIUM_ECONOMY_SEATS / 5 * Calculation::InertiaRouteService::MANAGEMENT_OVERHEAD
      expect(subject.premium_economy_fare).to be < subject.send(:premium_economy_revenue) / Calculation::InertiaRouteService::LONG_DISTANCE_PREMIUM_ECONOMY_SEATS / 4 * Calculation::InertiaRouteService::MANAGEMENT_OVERHEAD

      expect(subject.send(:premium_economy_flight_cost)).to be <= subject.premium_economy_fare * subject.premium_economy_seats_per_flight
    end
  end

  context "business_seats_per_flight" do
    let(:subject) { Calculation::InertiaRouteService.new(Airport.new, Airport.new, Date.today) }

    it "is less than SHORT_DISTANCE_BUSINESS_SEATS for a flight of less than SHORT_DISTANCE" do
      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::SHORT_DISTANCE / 2)

      assert subject.business_seats_per_flight == 0 || subject.business_seats_per_flight < Calculation::InertiaRouteService::SHORT_DISTANCE_BUSINESS_SEATS
    end

    it "is SHORT_DISTANCE_BUSINESS_SEATS for a flight of SHORT_DISTANCE" do
      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::SHORT_DISTANCE)

      assert subject.business_seats_per_flight == Calculation::InertiaRouteService::SHORT_DISTANCE_BUSINESS_SEATS
    end

    it "is between SHORT_DISTANCE_BUSINESS_SEATS and LONG_DISTANCE_BUSINESS_SEATS for a flight between SHORT_DISTANCE and LONG_DISTANCE" do
      allow(Calculation::Distance).to receive(:between_markets).and_return((Calculation::InertiaRouteService::SHORT_DISTANCE + Calculation::InertiaRouteService::LONG_DISTANCE) / 2)

      assert subject.business_seats_per_flight > Calculation::InertiaRouteService::SHORT_DISTANCE_BUSINESS_SEATS
      assert subject.business_seats_per_flight < Calculation::InertiaRouteService::LONG_DISTANCE_BUSINESS_SEATS
    end

    it "is LONG_DISTANCE_BUSINESS_SEATS for a flight of LONG_DISTANCE or more" do
      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::LONG_DISTANCE)

      assert subject.business_seats_per_flight == Calculation::InertiaRouteService::LONG_DISTANCE_BUSINESS_SEATS

      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::LONG_DISTANCE * 2)

      assert subject.business_seats_per_flight == Calculation::InertiaRouteService::LONG_DISTANCE_BUSINESS_SEATS
    end
  end

  context "economy_seats_per_flight" do
    let(:subject) { Calculation::InertiaRouteService.new(Airport.new, Airport.new, Date.today) }

    it "is less than SHORT_DISTANCE_ECONOMY_SEATS for a flight of less than SHORT_DISTANCE" do
      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::SHORT_DISTANCE / 2)

      assert subject.economy_seats_per_flight == 0 || subject.economy_seats_per_flight < Calculation::InertiaRouteService::SHORT_DISTANCE_ECONOMY_SEATS
    end

    it "is SHORT_DISTANCE_ECONOMY_SEATS for a flight of SHORT_DISTANCE" do
      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::SHORT_DISTANCE)

      assert subject.economy_seats_per_flight == Calculation::InertiaRouteService::SHORT_DISTANCE_ECONOMY_SEATS
    end

    it "is between SHORT_DISTANCE_ECONOMY_SEATS and LONG_DISTANCE_ECONOMY_SEATS for a flight between SHORT_DISTANCE and LONG_DISTANCE" do
      allow(Calculation::Distance).to receive(:between_markets).and_return((Calculation::InertiaRouteService::SHORT_DISTANCE + Calculation::InertiaRouteService::LONG_DISTANCE) / 2)

      assert subject.economy_seats_per_flight > Calculation::InertiaRouteService::SHORT_DISTANCE_ECONOMY_SEATS
      assert subject.economy_seats_per_flight < Calculation::InertiaRouteService::LONG_DISTANCE_ECONOMY_SEATS
    end

    it "is LONG_DISTANCE_ECONOMY_SEATS for a flight of LONG_DISTANCE or more" do
      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::LONG_DISTANCE)

      assert subject.economy_seats_per_flight == Calculation::InertiaRouteService::LONG_DISTANCE_ECONOMY_SEATS

      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::LONG_DISTANCE * 2)

      assert subject.economy_seats_per_flight == Calculation::InertiaRouteService::LONG_DISTANCE_ECONOMY_SEATS
    end
  end

  context "premium_economy_seats_per_flight" do
    let(:subject) { Calculation::InertiaRouteService.new(Airport.new, Airport.new, Date.today) }

    it "is less than SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS for a flight of less than SHORT_DISTANCE" do
      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::SHORT_DISTANCE / 2)

      assert subject.premium_economy_seats_per_flight == 0 || subject.premium_economy_seats_per_flight < Calculation::InertiaRouteService::SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS
    end

    it "is SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS for a flight of SHORT_DISTANCE" do
      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::SHORT_DISTANCE)

      assert subject.premium_economy_seats_per_flight == Calculation::InertiaRouteService::SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS
    end

    it "is between SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS and LONG_DISTANCE_PREMIUM_ECONOMY_SEATS for a flight between SHORT_DISTANCE and LONG_DISTANCE" do
      allow(Calculation::Distance).to receive(:between_markets).and_return((Calculation::InertiaRouteService::SHORT_DISTANCE + Calculation::InertiaRouteService::LONG_DISTANCE) / 2)

      assert subject.premium_economy_seats_per_flight > Calculation::InertiaRouteService::SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS
      assert subject.premium_economy_seats_per_flight < Calculation::InertiaRouteService::LONG_DISTANCE_PREMIUM_ECONOMY_SEATS
    end

    it "is LONG_DISTANCE_PREMIUM_ECONOMY_SEATS for a flight of LONG_DISTANCE or more" do
      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::LONG_DISTANCE)

      assert subject.premium_economy_seats_per_flight == Calculation::InertiaRouteService::LONG_DISTANCE_PREMIUM_ECONOMY_SEATS

      allow(Calculation::Distance).to receive(:between_markets).and_return(Calculation::InertiaRouteService::LONG_DISTANCE * 2)

      assert subject.premium_economy_seats_per_flight == Calculation::InertiaRouteService::LONG_DISTANCE_PREMIUM_ECONOMY_SEATS
    end
  end
end
