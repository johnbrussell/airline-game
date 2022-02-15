require "rails_helper"

RSpec.describe GlobalDemand do
  date = Date.today

  context "calculate" do
    it "correctly calls Calculation::TotalMarketDemand for each type of demand and adds the result" do
      market_1 = Fabricate(:market, name: "Tonga", country: "Tonga", country_group: "Tonga")
      market_2 = Fabricate(:market, name: "Tuvalu", country: "Tuvalu", country_group: "Tuvalu")
      market_3 = Fabricate(:market, name: "Nauru", country: "Nauru", country_group: "Nauru")

      origin_airport = Fabricate(:airport, market: market_3)

      expect(Calculation::TotalMarketDemand).to receive(:business).with(origin_airport, market_1, date).and_return 200
      expect(Calculation::TotalMarketDemand).to receive(:business).with(origin_airport, market_2, date).and_return 400
      expect(Calculation::TotalMarketDemand).to receive(:business).with(origin_airport, market_3, date).and_return 100

      expect(Calculation::TotalMarketDemand).to receive(:government).with(origin_airport, market_1, date).and_return 0
      expect(Calculation::TotalMarketDemand).to receive(:government).with(origin_airport, market_2, date).and_return 0
      expect(Calculation::TotalMarketDemand).to receive(:government).with(origin_airport, market_3, date).and_return 0

      expect(Calculation::TotalMarketDemand).to receive(:leisure).with(origin_airport, market_1, date).and_return 2000
      expect(Calculation::TotalMarketDemand).to receive(:leisure).with(origin_airport, market_2, date).and_return 4000
      expect(Calculation::TotalMarketDemand).to receive(:leisure).with(origin_airport, market_3, date).and_return 1000

      expect(Calculation::TotalMarketDemand).to receive(:tourist).with(origin_airport, market_1, date).and_return 20000
      expect(Calculation::TotalMarketDemand).to receive(:tourist).with(origin_airport, market_2, date).and_return 40000
      expect(Calculation::TotalMarketDemand).to receive(:tourist).with(origin_airport, market_3, date).and_return 10000

      global_demand_count = GlobalDemand.count

      actual = GlobalDemand.calculate(date, origin_airport)

      assert GlobalDemand.count == global_demand_count + 1

      last = GlobalDemand.last
      assert actual.id == last.id
      assert actual.date == date
      assert actual.airport_id == origin_airport.id
      assert actual.business == 700
      assert actual.government == 0
      assert actual.leisure == 7000
      assert actual.tourist == 70000
    end

    it "returns the known GlobalDemand when it has already been calculated" do
      origin_airport = Fabricate(:airport)

      GlobalDemand.create!(airport_id: 3, date: date, business: 1, government: 2, leisure: 3, tourist: 4, airport: origin_airport)

      expect(RivalCountryGroup).not_to receive(:all_rivals)
      expect(Calculation::TotalMarketDemand).not_to receive(:business)
      expect(Calculation::TotalMarketDemand).not_to receive(:government)
      expect(Calculation::TotalMarketDemand).not_to receive(:leisure)
      expect(Calculation::TotalMarketDemand).not_to receive(:tourist)

      global_demand_count = GlobalDemand.count

      actual = GlobalDemand.calculate(date, origin_airport)

      assert global_demand_count == GlobalDemand.count
      assert actual.date == date
      assert actual.airport_id == origin_airport.id
      assert actual.business == 1
      assert actual.government == 2
      assert actual.leisure == 3
      assert actual.tourist == 4
    end
  end
end
