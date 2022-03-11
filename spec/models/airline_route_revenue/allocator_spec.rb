require "rails_helper"

RSpec.describe AirlineRouteRevenue::Allocator do
  context "allocate" do
    let(:airline_route_1) { instance_double(AirlineRoute, reputation: 1) }
    let(:airline_route_2) { instance_double(AirlineRoute, reputation: 2) }
    let(:solicitations) { [[airline_route_1, [300, 300]], [airline_route_2, [600]]].to_h }

    it "returns zeros when there is no revenue to be allocated" do
      revenue = 0

      expected = [[airline_route_1, 0], [airline_route_2, 0]].to_h

      actual = AirlineRouteRevenue::Allocator.allocate(solicitations, revenue)

      expect(actual).to eq expected
    end

    it "weights allocations by reputation when there is not enough revenue to meet solicitations" do
      revenue = 600

      expected = [[airline_route_1, 300], [airline_route_2, 300]].to_h

      actual = AirlineRouteRevenue::Allocator.allocate(solicitations, revenue)

      expect(actual).to eq expected
    end

    it "doesn't overfill planes in the face of revenue overload" do
      revenue = 10000

      expected = [[airline_route_1, 600], [airline_route_2, 600]].to_h

      actual = AirlineRouteRevenue::Allocator.allocate(solicitations, revenue)

      expect(actual).to eq expected
    end
  end
end
