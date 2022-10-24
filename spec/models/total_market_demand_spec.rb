require "rails_helper"

RSpec.describe TotalMarketDemand do
  context "calculate" do
    let(:market_1) { Fabricate(:market, name: "Boston") }
    let(:market_2) { Fabricate(:market, name: "Worcester") }
    let(:mock_relative_demand) { instance_double(RelativeDemand, business: 1, government: 0, leisure: 3, tourist: 2) }
    let(:mock_zero_demand) { instance_double(RelativeDemand, business: 0, government: 0, leisure: 0, tourist: 0) }
    let(:date) { Date.today }

    it "returns existing TotalMarketDemand when it exists" do
      expected = TotalMarketDemand.create!(
        market: market_1,
        year: date.year,
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
      )

      total_market_demand_count = TotalMarketDemand.count
      actual = TotalMarketDemand.calculate(market_1, date)

      expect(actual).to eq expected
      expect(TotalMarketDemand.count).to eq total_market_demand_count
    end

    it "calculates a new TotalMarketDemand when none exists" do
      airport_1 = Fabricate(:airport, market: market_1, iata: "BOS")
      airport_2 = Fabricate(:airport, market: market_1, iata: "PSM")
      airport_3 = Fabricate(:airport, market: market_2, iata: "ORH")
      airport_4 = Fabricate(:airport, market: market_2, iata: "PVD")
      expect(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_1, airport_3, market_1, market_2).and_return mock_relative_demand
      expect(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_1, airport_4, market_1, market_2).and_return mock_relative_demand
      expect(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_1, nil, market_1, market_2).and_return mock_relative_demand
      expect(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_2, airport_3, market_1, market_2).and_return mock_relative_demand
      expect(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_2, airport_4, market_1, market_2).and_return mock_relative_demand
      expect(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_2, nil, market_1, market_2).and_return mock_relative_demand
      expect(RelativeDemand).to receive(:most_recent_or_initialize).with(date, nil, airport_3, market_1, market_2).and_return mock_relative_demand
      expect(RelativeDemand).to receive(:most_recent_or_initialize).with(date, nil, airport_4, market_1, market_2).and_return mock_relative_demand
      expect(RelativeDemand).to receive(:most_recent_or_initialize).with(date, nil, nil, market_1, market_2).and_return mock_relative_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_1, airport_1, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_1, airport_2, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_1, nil, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_2, airport_1, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_2, airport_2, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_2, nil, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, nil, airport_1, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, nil, airport_2, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, nil, nil, market_1, market_1).and_return mock_zero_demand
      market_1.reload

      expected_business = 9
      expected_government = 0
      expected_leisure = 27
      expected_tourist = 18

      total_market_demand_count = TotalMarketDemand.count
      actual = TotalMarketDemand.calculate(market_1, date)

      expect(TotalMarketDemand.count).to eq total_market_demand_count + 1
      expect(actual.business).to eq expected_business
      expect(actual.government).to eq expected_government
      expect(actual.leisure).to eq expected_leisure
      expect(actual.tourist).to eq expected_tourist
    end

    it "uses existing RelativeDemands when they exist" do
      RelativeDemand.create!(
        origin_market: market_1,
        destination_market: market_2,
        origin_airport_iata: "",
        destination_airport_iata: "",
        last_measured: date,
        business: 1,
        government: 2,
        leisure: 3,
        tourist: 4,
        pct_business: 1 / 3.0,
        pct_economy: 1 / 3.0,
        pct_premium_economy: 1 / 3.0,
      )
      airport_1 = Fabricate(:airport, market: market_1, iata: "BOS")
      airport_2 = Fabricate(:airport, market: market_1, iata: "PSM")
      airport_3 = Fabricate(:airport, market: market_2, iata: "ORH")
      airport_4 = Fabricate(:airport, market: market_2, iata: "PVD")
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_1, airport_1, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_1, airport_2, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_1, nil, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_2, airport_1, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_2, airport_2, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, airport_2, nil, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, nil, airport_1, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, nil, airport_2, market_1, market_1).and_return mock_zero_demand
      allow(RelativeDemand).to receive(:most_recent_or_initialize).with(date, nil, nil, market_1, market_1).and_return mock_zero_demand
      market_1.reload

      expected_business = 1
      expected_government = 2
      expected_leisure = 3
      expected_tourist = 4

      total_market_demand_count = TotalMarketDemand.count
      actual = TotalMarketDemand.calculate(market_1, date)

      expect(TotalMarketDemand.count).to eq total_market_demand_count + 1
      expect(actual.business).to eq expected_business
      expect(actual.government).to eq expected_government
      expect(actual.leisure).to eq expected_leisure
      expect(actual.tourist).to eq expected_tourist
    end
  end
end
