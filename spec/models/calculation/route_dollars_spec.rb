require "rails_helper"

RSpec.describe Calculation::RouteDollars do
  before(:each) do
    route_demand = instance_double(RouteDemand, business: 100, government: 10, leisure: 2000, tourist: 200)
    allow(RouteDemand).to receive(:calculate).and_return(route_demand)

    global_demand = instance_double(GlobalDemand, business: 1000, government: 1000, leisure: 100000, tourist: 40000)
    allow(GlobalDemand).to receive(:calculate).and_return(global_demand)

    market_dollars = instance_double(Calculation::MarketDollars, business: 5000, government: 10000, leisure: 50000, tourist: 1000)
    allow(Calculation::MarketDollars).to receive(:new).and_return(market_dollars)
  end

  context "business" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport)
      destination = Fabricate(:airport, market: origin.market)
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.business).to eq 1000
    end
  end

  context "government" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport)
      destination = Fabricate(:airport, market: origin.market)
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.government).to eq 200
    end
  end

  context "leisure" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport)
      destination = Fabricate(:airport, market: origin.market)
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.leisure).to eq 2000
    end
  end

  context "tourist" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport)
      destination = Fabricate(:airport, market: origin.market)
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.tourist).to eq 10
    end
  end
end
