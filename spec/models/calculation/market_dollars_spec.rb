require "rails_helper"

RSpec.describe Calculation::MarketDollars do
  date = Date.today
  island_airport = Airport.new(market: Market.new(is_island: true, income: 10000))
  mainland_airport = Airport.new(market: Market.new(is_island: false, income: 10000))

  let(:market_population_calculator) { instance_double(Calculation::MarketPopulation) }

  before(:each) do
    allow(market_population_calculator).to receive(:government_workers).and_return 10
    allow(market_population_calculator).to receive(:population).and_return 100
    allow(market_population_calculator).to receive(:tourists).and_return 20
  end

  context "business" do
    it "calculates correctly" do
      expect(Calculation::MarketPopulation).to receive(:new).with(mainland_airport.market, date).and_return(market_population_calculator)

      subject = described_class.new(mainland_airport, date)

      assert_in_epsilon subject.business, 1200, 0.0000001
    end

    it "calculates islands correctly" do
      expect(Calculation::MarketPopulation).to receive(:new).with(island_airport.market, date).and_return(market_population_calculator)

      subject = described_class.new(island_airport, date)

      expect(subject.business).to eq 12000
    end
  end

  context "government" do
    it "calculates correctly" do
      expect(Calculation::MarketPopulation).to receive(:new).with(mainland_airport.market, date).and_return(market_population_calculator)

      subject = described_class.new(mainland_airport, date)

      expect(subject.government).to eq 6000
    end

    it "calculates islands correctly" do
      expect(Calculation::MarketPopulation).to receive(:new).with(island_airport.market, date).and_return(market_population_calculator)

      subject = described_class.new(island_airport, date)

      expect(subject.government).to eq 6000
    end
  end

  context "leisure" do
    it "calculates correctly" do
      expect(Calculation::MarketPopulation).to receive(:new).with(mainland_airport.market, date).and_return(market_population_calculator)

      subject = described_class.new(mainland_airport, date)

      expect(subject.leisure).to eq 8800
    end

    it "calculates islands correctly" do
      expect(Calculation::MarketPopulation).to receive(:new).with(island_airport.market, date).and_return(market_population_calculator)

      subject = described_class.new(island_airport, date)

      assert_in_delta subject.leisure, 88000, 0.00000001
    end
  end

  context "tourist" do
    it "calculates correctly" do
      expect(Calculation::MarketPopulation).to receive(:new).with(mainland_airport.market, date).and_return(market_population_calculator)

      subject = described_class.new(mainland_airport, date)

      expect(subject.tourist).to eq 6000
    end

    it "calculates islands correctly" do
      expect(Calculation::MarketPopulation).to receive(:new).with(island_airport.market, date).and_return(market_population_calculator)

      subject = described_class.new(island_airport, date)

      expect(subject.tourist).to eq 6000
    end
  end
end
