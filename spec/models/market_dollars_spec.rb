require "rails_helper"

RSpec.describe MarketDollars do
  context "calculate" do
    let(:market) { Fabricate(:market) }
    let(:date) { Date.today }
    let(:calculator) { instance_double(Calculation::MarketDollars, business: 1, government: 2, leisure: 3, tourist: 4) }

    before(:each) do
      Fabricate(:airport, market: market)
      market.reload
    end

    it "calculates for the market if none exists" do
      airport_1 = Airport.last
      expect(Calculation::MarketDollars).to receive(:new).with(airport_1, date, market).and_return(calculator)

      existing_record_count = MarketDollars.count

      actual = MarketDollars.calculate(market, date)

      expect(MarketDollars.count).to eq existing_record_count + 1
      expect(actual.business).to eq 1
      expect(actual.government).to eq 2
      expect(actual.leisure).to eq 3
      expect(actual.tourist).to eq 4
    end

    it "returns the existing record if one exists" do
      MarketDollars.create!(
        market: market,
        year: date.year,
        business: 4,
        government: 3,
        leisure: 2,
        tourist: 1,
      )

      existing_record_count = MarketDollars.count

      actual = MarketDollars.calculate(market, date)

      expect(MarketDollars.count).to eq existing_record_count
      expect(actual.business).to eq 4
      expect(actual.government).to eq 3
      expect(actual.leisure).to eq 2
      expect(actual.tourist).to eq 1
    end
  end
end
