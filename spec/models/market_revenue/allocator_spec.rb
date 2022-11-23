require "rails_helper"

RSpec.describe MarketRevenue::Allocator do
  context "allocate_route_dollars" do
    let(:airplane_route_1) { instance_double(AirplaneRoute) }
    let(:reputation_data_1) { Calculation::ReputationData.new(nil, 100, 1, 1, 1) }
    let(:airplane_route_2) { instance_double(AirplaneRoute) }
    let(:reputation_data_2) { Calculation::ReputationData.new(nil, 50, 2, 1, 1) }
    let(:route_reputation) { instance_double(Calculation::RouteReputation) }

    before(:each) do
      allow(Calculation::RouteReputation).to receive(:new).and_return route_reputation
      allow(route_reputation).to receive(:reputation).and_return Calculation::RouteReputation::MIN_REPUTATION
    end

    it "allocates correctly when there are more dollars than fare-seats available" do
      available_capacity = [
        MarketRevenue::Capacity.new(airplane_route_1, reputation_data_1, 100, "FUN", "INU", nil, nil),
        MarketRevenue::Capacity.new(airplane_route_2, reputation_data_2, 200, "FUN", "INU", nil, nil),
      ]

      available_route_dollars = [
        MarketRevenue::RevenuePotential.new(30000, "FUN", "INU"),
        MarketRevenue::RevenuePotential.new(1000, "FUN", ""),
      ]

      actual = MarketRevenue::Allocator.new(available_capacity, available_route_dollars).allocate_route_dollars

      expect(actual.sum(&:available_seats)).to eq 0
    end

    it "allocates correctly when there are more fare-seats available than dollars to fill them" do
      available_capacity = [
        MarketRevenue::Capacity.new(airplane_route_1, reputation_data_1, 100, "FUN", "INU", nil, nil),
        MarketRevenue::Capacity.new(airplane_route_2, reputation_data_2, 200, "FUN", "INU", nil, nil),
      ]

      available_route_dollars = [
        MarketRevenue::RevenuePotential.new(8000, "", ""),
        MarketRevenue::RevenuePotential.new(1000, "FUN", ""),
        MarketRevenue::RevenuePotential.new(1000, "", "INU"),
      ]

      actual = MarketRevenue::Allocator.new(available_capacity, available_route_dollars).allocate_route_dollars
      actual_1 = actual.select { |ac| ac.airplane_route == airplane_route_1 }.first
      actual_2 = actual.select { |ac| ac.airplane_route == airplane_route_2 }.first

      # Since reputation is equal, dollars should be allocated equally to each flight, so at a 2:1 ratio to route 2 because it has two frequencies.
      #  Route 2's load factor is double route 1's because its fares are half route 1's.  All three flights have equal seat counts.
      assert_in_epsilon actual_1.available_seats, 100 * 2 / 3.0, 0.00000001
      assert_in_epsilon actual_2.available_seats, 200 * 1 / 3.0, 0.00000001
    end

    it "correctly excludes invalid flights" do
      available_capacity = [
        MarketRevenue::Capacity.new(airplane_route_1, reputation_data_1, 100, "FUN", "INU", nil, nil),
        MarketRevenue::Capacity.new(airplane_route_2, reputation_data_2, 200, "FUN", "INU", nil, nil),
      ]

      available_route_dollars = [
        MarketRevenue::RevenuePotential.new(30000, "FUN", "MAJ"),
        MarketRevenue::RevenuePotential.new(30000, "MAJ", "INU"),
        MarketRevenue::RevenuePotential.new(30000, "INU", "FUN"),
        MarketRevenue::RevenuePotential.new(30000, "", "FUN"),
        MarketRevenue::RevenuePotential.new(30000, "INU", ""),
      ]

      actual = MarketRevenue::Allocator.new(available_capacity, available_route_dollars).allocate_route_dollars

      expect(actual.sum(&:available_seats)).to eq 300
    end

    it "correctly scales for reputation" do
      all_reputation_data = [reputation_data_1, reputation_data_2]
      route_reputation_1 = instance_double(Calculation::RouteReputation)
      route_reputation_2 = instance_double(Calculation::RouteReputation)
      allow(Calculation::RouteReputation).to receive(:new).with(reputation_data_1, all_reputation_data).and_return route_reputation_1
      allow(Calculation::RouteReputation).to receive(:new).with(reputation_data_2, all_reputation_data).and_return route_reputation_2
      allow(route_reputation_1).to receive(:reputation).and_return Calculation::RouteReputation::MIN_REPUTATION * 2
      allow(route_reputation_2).to receive(:reputation).and_return Calculation::RouteReputation::MIN_REPUTATION

      available_capacity = [
        MarketRevenue::Capacity.new(airplane_route_1, reputation_data_1, 100, "FUN", "INU", nil, nil),
        MarketRevenue::Capacity.new(airplane_route_2, reputation_data_2, 200, "FUN", "INU", nil, nil),
      ]

      available_route_dollars = [
        MarketRevenue::RevenuePotential.new(8000, "", ""),
        MarketRevenue::RevenuePotential.new(1000, "FUN", ""),
        MarketRevenue::RevenuePotential.new(1000, "", "INU"),
      ]

      actual = MarketRevenue::Allocator.new(available_capacity, available_route_dollars).allocate_route_dollars
      actual_1 = actual.select { |ac| ac.airplane_route == airplane_route_1 }.first
      actual_2 = actual.select { |ac| ac.airplane_route == airplane_route_2 }.first

      # Dollars should be allocated 2:1 to flights on route 1 vs route 2.  So, dollars are allocated equally to each route because there are two frequencies on route_2 and one on route_1.
      assert_in_epsilon actual_1.available_seats, 100 * 1 / 2.0, 0.00000001
      assert_in_epsilon actual_2.available_seats, 200 * 1 / 2.0, 0.00000001
    end

    it "returns all empty seats when there is no revenue potential" do
      available_capacity = [
        MarketRevenue::Capacity.new(airplane_route_1, reputation_data_1, 100, "FUN", "INU", nil, nil),
        MarketRevenue::Capacity.new(airplane_route_2, reputation_data_2, 200, "FUN", "INU", nil, nil),
      ]

      available_route_dollars = []

      actual = MarketRevenue::Allocator.new(available_capacity, available_route_dollars).allocate_route_dollars

      expect(actual.sum(&:available_seats)).to eq 300
    end

    it "returns an empty array when there is no capacity" do
      available_capacity = []

      available_route_dollars = [
        MarketRevenue::RevenuePotential.new(30000, "", ""),
      ]

      actual = MarketRevenue::Allocator.new(available_capacity, available_route_dollars).allocate_route_dollars

      expect(actual).to eq []
    end
  end
end
