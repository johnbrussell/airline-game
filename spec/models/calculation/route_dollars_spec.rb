require "rails_helper"

RSpec.describe Calculation::RouteDollars do
  before(:each) do
    airport = instance_double(Airport)

    market_dollars = instance_double(Calculation::MarketDollars, business: 5000, government: 10000, leisure: 50000, tourist: 1000)
    allow(Calculation::MarketDollars).to receive(:new).and_return(market_dollars)

    class_calculator = instance_double(
      Calculation::ClassOfService,
      pct_business_dollars_business: 0.10,
      pct_business_dollars_economy: 0.70,
      pct_business_dollars_premium_economy: 0.20,
      pct_leisure_dollars_business: 0.01,
      pct_leisure_dollars_economy: 0.90,
      pct_leisure_dollars_premium_economy: 0.09,
    )
    allow(Calculation::ClassOfService).to receive(:new).and_return(class_calculator)

    market_dollars = instance_double(MarketDollars, business: 1000.0, government: 100.0, leisure: 10000.0, tourist: 1000.0)
    allow(MarketDollars).to receive(:calculate).and_return market_dollars

    relative_demand = instance_double(RelativeDemand, business: 1.0, government: 2.0, leisure: 3.0, tourist: 4.0, distance: 5)
    allow(RelativeDemand).to receive(:most_recent_or_initialize).and_return relative_demand

    total_market_demand = instance_double(TotalMarketDemand, business: 100.0, government: 100.0, leisure: 1000.0, tourist: 1000.0)
    allow(TotalMarketDemand).to receive(:calculate).and_return total_market_demand
  end

  context "business_class_dollars" do
    let(:origin_market) { Fabricate(:market, name: "New Haven") }
    let(:destination_market) { Fabricate(:market, name: "New York City") }
    let(:origin_airport) { Fabricate(:airport, iata: "HVN", market: origin_market) }
    let(:destination_airport) { Fabricate(:airport, iata: "LGA", market: destination_market) }

    it "calculates correctly" do
      subject = Calculation::RouteDollars.new(Date.today, origin_market, destination_market, origin_airport, destination_airport)

      expect(subject.send(:business_dollars)).to eq 12
      expect(subject.send(:leisure_dollars)).to eq 34
      assert_in_epsilon subject.business_class_dollars, 1.54, 0.000000001
    end

    it "returns 0 when total market demand is 0" do
      total_market_demand = instance_double(TotalMarketDemand, business: 0, government: 0, leisure: 0, tourist: 0)
      allow(TotalMarketDemand).to receive(:calculate).and_return total_market_demand

      subject = Calculation::RouteDollars.new(Date.today, origin_market, destination_market, origin_airport, destination_airport)

      expect(subject.business_class_dollars).to eq 0
    end
  end

  context "economy_class_dollars" do
    let(:origin_market) { Fabricate(:market, name: "New Haven") }
    let(:destination_market) { Fabricate(:market, name: "New York City") }
    let(:origin_airport) { Fabricate(:airport, iata: "HVN", market: origin_market) }
    let(:destination_airport) { Fabricate(:airport, iata: "LGA", market: destination_market) }

    it "calculates correctly" do
      subject = Calculation::RouteDollars.new(Date.today, origin_market, destination_market, origin_airport, destination_airport)

      assert_in_epsilon subject.economy_class_dollars, 12 * 0.7 + 34 * 0.9, 0.000000001
    end

    it "returns 0 when total market demand is 0" do
      total_market_demand = instance_double(TotalMarketDemand, business: 0, government: 0, leisure: 0, tourist: 0)
      allow(TotalMarketDemand).to receive(:calculate).and_return total_market_demand

      subject = Calculation::RouteDollars.new(Date.today, origin_market, destination_market, origin_airport, destination_airport)

      expect(subject.economy_class_dollars).to eq 0
    end
  end

  context "premium_economy_class_dollars" do
    let(:origin_market) { Fabricate(:market, name: "New Haven") }
    let(:destination_market) { Fabricate(:market, name: "New York City") }
    let(:origin_airport) { Fabricate(:airport, iata: "HVN", market: origin_market) }
    let(:destination_airport) { Fabricate(:airport, iata: "LGA", market: destination_market) }

    it "calculates correctly" do
      subject = Calculation::RouteDollars.new(Date.today, origin_market, destination_market, origin_airport, destination_airport)

      assert_in_epsilon subject.premium_economy_class_dollars, 12 * 0.2 + 34 * 0.09, 0.000000001
    end

    it "returns 0 when total market demand is 0" do
      total_market_demand = instance_double(TotalMarketDemand, business: 0, government: 0, leisure: 0, tourist: 0)
      allow(TotalMarketDemand).to receive(:calculate).and_return total_market_demand

      subject = Calculation::RouteDollars.new(Date.today, origin_market, destination_market, origin_airport, destination_airport)

      expect(subject.premium_economy_class_dollars).to eq 0
    end
  end
end
