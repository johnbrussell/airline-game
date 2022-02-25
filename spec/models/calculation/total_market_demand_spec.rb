require "rails_helper"

RSpec.describe Calculation::TotalMarketDemand do
  date = Date.today

  context "with one airport in the destination market" do
    origin_airport = Airport.new
    airport = Airport.new
    destination_market = Market.new(airports: [airport])
    expected_demand = 4

    context "business demand" do
      it "the total market demand is equivalent to the airport demand" do
        mock_business_demand = instance_double(Calculation::ResidentDemand)

        expect(Calculation::ResidentDemand).to receive(:new).with(origin_airport, airport, date).and_return mock_business_demand
        expect(mock_business_demand).to receive(:business_demand).with(no_args).and_return(expected_demand)

        actual = Calculation::TotalMarketDemand.business(origin_airport, destination_market, date)

        assert actual == expected_demand
      end
    end

    context "government demand" do
      it "the total market demand is equivalent to the airport demand" do
        mock_government_demand = instance_double(Calculation::GovernmentDemand)

        expect(Calculation::GovernmentDemand).to receive(:new).with(origin_airport, airport, date).and_return mock_government_demand
        expect(mock_government_demand).to receive(:demand).with(no_args).and_return(expected_demand)

        actual = Calculation::TotalMarketDemand.government(origin_airport, destination_market, date)

        assert actual == expected_demand
      end
    end

    context "leisure demand" do
      it "the total market demand is equivalent to the airport demand" do
        mock_leisure_demand = instance_double(Calculation::ResidentDemand)

        expect(Calculation::ResidentDemand).to receive(:new).with(origin_airport, airport, date).and_return mock_leisure_demand
        expect(mock_leisure_demand).to receive(:leisure_demand).with(no_args).and_return(expected_demand)

        actual = Calculation::TotalMarketDemand.leisure(origin_airport, destination_market, date)

        assert actual == expected_demand
      end
    end

    context "tourist demand" do
      it "the total market demand is equivalent to the airport demand" do
        mock_tourist_demand = instance_double(Calculation::TouristDemand)

        expect(Calculation::TouristDemand).to receive(:new).with(origin_airport, airport, date).and_return mock_tourist_demand
        expect(mock_tourist_demand).to receive(:demand).with(no_args).and_return(expected_demand)

        actual = Calculation::TotalMarketDemand.tourist(origin_airport, destination_market, date)

        assert actual == expected_demand
      end
    end
  end

  context "with multiple airports in the destination market" do
    origin_airport = Airport.new
    airport_1 = Airport.new(exclusive_catchment: 1)
    airport_2 = Airport.new(exclusive_catchment: 50)
    airport_3 = Airport.new(exclusive_catchment: 9)
    destination_market = Market.new(airports: [airport_1, airport_2, airport_3])
    demand_airport_1 = 164 # has the most demand, so has the largest shared demand.  Take all of partial and shared demand.
    demand_airport_2 = 90  # only take exclusive demand, which is 50/90ths of this (50)
    demand_airport_3 = 98 # only take exlusive demand, which is 9/49ths of this (18)
    expected_demand = 232 # 164 + 50 + 18 = 232

    context "business demand" do
      it "the total market demand is equivalent to the exclusive demands plus the maximum shared demand" do
        mock_airport_1_demand = instance_double(Calculation::ResidentDemand)
        mock_airport_2_demand = instance_double(Calculation::ResidentDemand)
        mock_airport_3_demand = instance_double(Calculation::ResidentDemand)

        expect(Calculation::ResidentDemand).to receive(:new).with(origin_airport, airport_1, date).and_return mock_airport_1_demand
        expect(Calculation::ResidentDemand).to receive(:new).with(origin_airport, airport_2, date).and_return mock_airport_2_demand
        expect(Calculation::ResidentDemand).to receive(:new).with(origin_airport, airport_3, date).and_return mock_airport_3_demand
        expect(mock_airport_1_demand).to receive(:business_demand).with(no_args).and_return(demand_airport_1)
        expect(mock_airport_2_demand).to receive(:business_demand).with(no_args).and_return(demand_airport_2)
        expect(mock_airport_3_demand).to receive(:business_demand).with(no_args).and_return(demand_airport_3)

        actual = Calculation::TotalMarketDemand.business(origin_airport, destination_market, date)

        assert actual == expected_demand
      end
    end

    context "government demand" do
      it "the total market demand is equivalent to the exclusive demands plus the maximum shared demand" do
        mock_airport_2_demand = instance_double(Calculation::GovernmentDemand)
        mock_airport_1_demand = instance_double(Calculation::GovernmentDemand)
        mock_airport_3_demand = instance_double(Calculation::GovernmentDemand)

        expect(Calculation::GovernmentDemand).to receive(:new).with(origin_airport, airport_1, date).and_return mock_airport_1_demand
        expect(Calculation::GovernmentDemand).to receive(:new).with(origin_airport, airport_2, date).and_return mock_airport_2_demand
        expect(Calculation::GovernmentDemand).to receive(:new).with(origin_airport, airport_3, date).and_return mock_airport_3_demand
        expect(mock_airport_1_demand).to receive(:demand).with(no_args).and_return(demand_airport_1)
        expect(mock_airport_2_demand).to receive(:demand).with(no_args).and_return(demand_airport_2)
        expect(mock_airport_3_demand).to receive(:demand).with(no_args).and_return(demand_airport_3)

        actual = Calculation::TotalMarketDemand.government(origin_airport, destination_market, date)

        assert actual == expected_demand
      end
    end

    context "leisure demand" do
      it "the total market demand is equivalent to the exclusive demands plus the maximum shared demand" do
        mock_airport_1_demand = instance_double(Calculation::ResidentDemand)
        mock_airport_2_demand = instance_double(Calculation::ResidentDemand)
        mock_airport_3_demand = instance_double(Calculation::ResidentDemand)

        expect(Calculation::ResidentDemand).to receive(:new).with(origin_airport, airport_1, date).and_return mock_airport_1_demand
        expect(Calculation::ResidentDemand).to receive(:new).with(origin_airport, airport_2, date).and_return mock_airport_2_demand
        expect(Calculation::ResidentDemand).to receive(:new).with(origin_airport, airport_3, date).and_return mock_airport_3_demand
        expect(mock_airport_1_demand).to receive(:leisure_demand).with(no_args).and_return(demand_airport_1)
        expect(mock_airport_2_demand).to receive(:leisure_demand).with(no_args).and_return(demand_airport_2)
        expect(mock_airport_3_demand).to receive(:leisure_demand).with(no_args).and_return(demand_airport_3)

        actual = Calculation::TotalMarketDemand.leisure(origin_airport, destination_market, date)

        assert actual == expected_demand
      end
    end

    context "tourist demand" do
      it "the total market demand is equivalent to the exclusive demands plus the maximum shared demand" do
        mock_airport_2_demand = instance_double(Calculation::TouristDemand)
        mock_airport_1_demand = instance_double(Calculation::TouristDemand)
        mock_airport_3_demand = instance_double(Calculation::TouristDemand)

        expect(Calculation::TouristDemand).to receive(:new).with(origin_airport, airport_1, date).and_return mock_airport_1_demand
        expect(Calculation::TouristDemand).to receive(:new).with(origin_airport, airport_2, date).and_return mock_airport_2_demand
        expect(Calculation::TouristDemand).to receive(:new).with(origin_airport, airport_3, date).and_return mock_airport_3_demand
        expect(mock_airport_1_demand).to receive(:demand).with(no_args).and_return(demand_airport_1)
        expect(mock_airport_2_demand).to receive(:demand).with(no_args).and_return(demand_airport_2)
        expect(mock_airport_3_demand).to receive(:demand).with(no_args).and_return(demand_airport_3)

        actual = Calculation::TotalMarketDemand.tourist(origin_airport, destination_market, date)

        assert actual == expected_demand
      end
    end
  end
end
