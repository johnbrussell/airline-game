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
  end

  context "business" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.business).to eq 1000
    end
  end

  context "exclusive_business" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.exclusive_business).to eq 100
    end
  end

  context "exclusive_government" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.exclusive_government).to eq 20
    end
  end

  context "exclusive_leisure" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.exclusive_leisure).to eq 200
    end
  end

  context "exclusive_tourist" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.exclusive_tourist).to eq 1
    end
  end

  context "government" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.government).to eq 200
    end
  end

  context "leisure" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.leisure).to eq 2000
    end
  end

  context "tourist" do
    it "calculates correctly" do
      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin, destination)

      expect(subject.tourist).to eq 10
    end
  end

  context "divide by zero errors" do
    it "do not occur" do

      date = Date.today
      origin = Fabricate(:airport, iata: "XWA")
      destination = Fabricate(:airport, market: origin.market, iata: "DIK")
      subject = Calculation::RouteDollars.new(date, origin, destination)

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
