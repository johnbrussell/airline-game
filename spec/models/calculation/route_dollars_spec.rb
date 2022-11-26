require "rails_helper"

RSpec.describe Calculation::RouteDollars do
  before(:each) do
    airport = instance_double(Airport)

    route_demand = instance_double(RouteDemand, business: 100, exclusive_business: 10, exclusive_government: 1, exclusive_leisure: 200, exclusive_tourist: 20, government: 10, leisure: 2000, tourist: 200)
    allow(RouteDemand).to receive(:calculate).and_return(route_demand)

    global_demand = instance_double(GlobalDemand, business: 1000, government: 1000, leisure: 100000, tourist: 40000, airport: airport)
    allow(GlobalDemand).to receive(:calculate).and_return(global_demand)

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

  context "business" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin.market, destination.market, origin, destination)

      expect(subject.business).to eq 1000
    end
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

  context "exclusive_business" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin.market, destination.market, origin, destination)

      expect(subject.exclusive_business).to eq 100
    end
  end

  context "exclusive_government" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin.market, destination.market, origin, destination)

      expect(subject.exclusive_government).to eq 20
    end
  end

  context "exclusive_leisure" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin.market, destination.market, origin, destination)

      expect(subject.exclusive_leisure).to eq 200
    end
  end

  context "exclusive_tourist" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin.market, destination.market, origin, destination)

      expect(subject.exclusive_tourist).to eq 1
    end
  end

  context "government" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin.market, destination.market, origin, destination)

      expect(subject.government).to eq 200
    end
  end

  context "leisure" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin.market, destination.market, origin, destination)

      expect(subject.leisure).to eq 2000
    end
  end

  context "tourist" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin.market, destination.market, origin, destination)

      expect(subject.tourist).to eq 10
    end
  end

  context "divide by zero errors" do
    it "do not occur" do

      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin.market, destination.market, origin, destination)

      zero_global_demand = instance_double(GlobalDemand, business: 0, government: 0, leisure: 0, tourist: 0, airport: origin)
      allow(GlobalDemand).to receive(:calculate).and_return(zero_global_demand)

      expect(subject.business).to eq 0
      expect(subject.exclusive_business).to eq 0
      expect(subject.exclusive_government).to eq 0
      expect(subject.exclusive_leisure).to eq 0
      expect(subject.exclusive_tourist).to eq 0
      expect(subject.government).to eq 0
      expect(subject.leisure).to eq 0
      expect(subject.tourist).to eq 0
    end
  end
end
