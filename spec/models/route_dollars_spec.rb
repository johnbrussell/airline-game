require "rails_helper"

RSpec.describe RouteDollars do
  context "calculate" do
    let(:market_1) { Fabricate(:market, name: "Altoona") }
    let(:market_2) { Fabricate(:market, name: "Johnstown") }
    let(:date) { Date.today }

    it "calcuates a new RouteDollars if none exists" do
      route_dollars_count = RouteDollars.count

      route_dollars_calculator = instance_double(Calculation::RouteDollars, business_class_dollars: 1, economy_class_dollars: 2, premium_economy_class_dollars: 3)
      allow(Calculation::RouteDollars).to receive(:new).with(date, market_1, market_2, nil, nil).and_return(route_dollars_calculator)

      expect(RelativeDemand).to receive(:calculate_between_markets).with(date, market_1, market_2)

      actual = RouteDollars.calculate(date, market_1, market_2, nil, nil)

      expect(RouteDollars.count).to eq route_dollars_count + 1
      expect(actual.date).to eq date
      expect(actual.business).to eq 1
      expect(actual.economy).to eq 2
      expect(actual.premium_economy).to eq 3
      expect(actual.origin_airport_iata).to eq ""
      expect(actual.destination_airport_iata).to eq ""
    end

    it "uses the last valid RouteDollars if one exists" do
      RouteDollars.create!(
        origin_market: market_2,
        destination_market: market_1,
        origin_airport_iata: "",
        destination_airport_iata: "",
        date: date,
        business: 1,
        economy: 2,
        premium_economy: 3,
      )

      route_dollars_count = RouteDollars.count

      expect(RelativeDemand).not_to receive(:calculate_between_markets)

      actual = RouteDollars.calculate(date, market_2, market_1, nil, nil)

      expect(RouteDollars.count).to eq route_dollars_count
      expect(actual.date).to eq date
      expect(actual.business).to eq 1
      expect(actual.economy).to eq 2
      expect(actual.premium_economy).to eq 3
      expect(actual.origin_airport_iata).to eq ""
      expect(actual.destination_airport_iata).to eq ""
    end
  end
end
