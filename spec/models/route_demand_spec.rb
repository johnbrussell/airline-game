require "rails_helper"

RSpec.describe RouteDemand do
  context "calculate" do
    it "correctly calculates the demand" do
      market_1 = Fabricate(:market, name: "Foo")
      market_2 = Fabricate(:market, name: "Bar")
      airport_1 = Fabricate(:airport, iata: "TVC", market: market_1, exclusive_catchment: 1)
      airport_2 = Fabricate(:airport, market: market_2, exclusive_catchment: 10)
      date = Date.today

      mock_resident_demand = double
      mock_government_demand = double
      mock_tourist_demand = double

      expect(Calculation::ResidentDemand).to receive(:new).twice.with(airport_1, airport_2, date).and_return(mock_resident_demand)
      expect(Calculation::GovernmentDemand).to receive(:new).with(airport_1, airport_2, date).and_return(mock_government_demand)
      expect(Calculation::TouristDemand).to receive(:new).with(airport_1, airport_2, date).and_return(mock_tourist_demand)

      expect(mock_resident_demand).to receive(:business_demand).and_return(4)
      expect(mock_government_demand).to receive(:demand).and_return(1)
      expect(mock_resident_demand).to receive(:leisure_demand).and_return(10)
      expect(mock_tourist_demand).to receive(:demand).and_return(40)

      route_demand_count = RouteDemand.count

      route_demand = RouteDemand.calculate(date, airport_1, airport_2)

      expect(RouteDemand.count).to eq route_demand_count + 1
      expect(route_demand.origin_iata).to eq airport_1.iata
      expect(route_demand.destination_iata).to eq airport_2.iata
      expect(route_demand.year).to eq date.year
      expect(route_demand.business).to eq 4
      expect(route_demand.exclusive_business).to eq 0.4
      expect(route_demand.exclusive_government).to eq 0.1
      expect(route_demand.exclusive_leisure).to eq 1
      expect(route_demand.exclusive_tourist).to eq 4
      expect(route_demand.government).to eq 1
      expect(route_demand.leisure).to eq 10
      expect(route_demand.tourist).to eq 40
    end

    it "uses a saved record if one exists" do
      airport_1 = Fabricate(:airport, iata: "MQT")
      airport_2 = Fabricate(:airport, market: airport_1.market)

      RouteDemand.create!(
        origin_iata: airport_1.iata,
        destination_iata: airport_2.iata,
        year: Date.today.year,
        business: 8,
        exclusive_business: 8,
        exclusive_government: 2,
        exclusive_leisure: 20,
        exclusive_tourist: 80,
        government: 2,
        leisure: 20,
        tourist: 80,
      )

      expect(Calculation::ResidentDemand).not_to receive(:new)
      expect(Calculation::GovernmentDemand).not_to receive(:new)
      expect(Calculation::TouristDemand).not_to receive(:new)

      route_demand_count = RouteDemand.count

      route_demand = RouteDemand.calculate(Date.today, airport_1, airport_2)

      expect(RouteDemand.count).to eq route_demand_count
      expect(route_demand.origin_iata).to eq airport_1.iata
      expect(route_demand.destination_iata).to eq airport_2.iata
      expect(route_demand.year).to eq Date.today.year
      expect(route_demand.business).to eq 8
      expect(route_demand.exclusive_business).to eq 8
      expect(route_demand.exclusive_government).to eq 2
      expect(route_demand.exclusive_leisure).to eq 20
      expect(route_demand.exclusive_tourist).to eq 80
      expect(route_demand.government).to eq 2
      expect(route_demand.leisure).to eq 20
      expect(route_demand.tourist).to eq 80
    end
  end
end
