require "rails_helper"

RSpec.describe Calculation::MaximumRevenuePotential do
  before(:each) do
    date = Date.today
    airport_1 = Fabricate(:airport, iata: "LGA")
    airport_2 = Fabricate(:airport, iata: "BOS", market: airport_1.market)
    route_dollars = instance_double(Calculation::RouteDollars, business: 1000, exclusive_business: 100, exclusive_government: 100, exclusive_leisure: 100, exclusive_tourist: 100, government: 1000, leisure: 1000, tourist: 1000)
    expect(Calculation::RouteDollars).to receive(:new).with(date, airport_1, airport_2).and_return(route_dollars)
  end

  week_multiplier = 1.0 / Calculation::MaximumRevenuePotential::WEEKS_PER_YEAR

  context "max_economy_class_revenue_per_week" do
    it "is all of the revenue for a flight of zero distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 0
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      assert_in_epsilon subject.max_economy_class_revenue_per_week, 4000 * week_multiplier, 0.0000001
    end

    it "diminishes for a longer flight" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 1
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      expect(subject.max_economy_class_revenue_per_week).to be < 4000 * week_multiplier
    end

    it "stops diminishing for very long flights" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = Calculation::MaximumRevenuePotential::PREMIUM_ECONOMY_MAX_DISTANCE
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      original_dollars_pe = subject.max_economy_class_revenue_per_week

      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      expect(subject.max_economy_class_revenue_per_week).to be < original_dollars_pe

      distance = Calculation::MaximumRevenuePotential::BUSINESS_MAX_DISTANCE
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      original_dollars_bus = subject.max_economy_class_revenue_per_week

      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      expect(subject.max_economy_class_revenue_per_week).to eq original_dollars_bus
    end
  end

  context "max_premium_economy_class_revenue_per_week" do
    it "is zero for a flight of zero distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 0
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      assert_in_epsilon subject.max_premium_economy_class_revenue_per_week, 0, 0.0000001
    end

    it "increases for a longer flight" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 1
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      expect(subject.max_premium_economy_class_revenue_per_week).to be > 0
    end

    it "stops increasing for a flight of longer distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = Calculation::MaximumRevenuePotential::PREMIUM_ECONOMY_MAX_DISTANCE
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      original_ratio_business = subject.send(:ratio_business_dollars_premium_economy)
      original_ratio_leisure = subject.send(:ratio_leisure_dollars_premium_economy)
      original_dollars = subject.max_premium_economy_class_revenue_per_week

      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      expect(subject.max_premium_economy_class_revenue_per_week).to be < original_dollars
      expect(subject.send(:ratio_business_dollars_premium_economy)).to eq original_ratio_business
      expect(subject.send(:ratio_leisure_dollars_premium_economy)).to eq original_ratio_leisure
    end
  end

  context "max_exclusive_economy_class_revenue_per_week" do
    it "is all of the revenue for a flight of zero distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 0
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      assert_in_epsilon subject.max_exclusive_economy_class_revenue_per_week, 400 * week_multiplier, 0.0000001
    end

    it "diminishes for a longer flight" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 1
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      expect(subject.max_exclusive_economy_class_revenue_per_week).to be < 400 * week_multiplier
    end

    it "stops diminishing for very long flights" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = Calculation::MaximumRevenuePotential::PREMIUM_ECONOMY_MAX_DISTANCE
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      original_dollars_pe = subject.max_exclusive_economy_class_revenue_per_week

      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      expect(subject.max_exclusive_economy_class_revenue_per_week).to be < original_dollars_pe

      distance = Calculation::MaximumRevenuePotential::BUSINESS_MAX_DISTANCE
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      original_dollars_bus = subject.max_exclusive_economy_class_revenue_per_week

      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      expect(subject.max_exclusive_economy_class_revenue_per_week).to eq original_dollars_bus
    end
  end

  context "max_exclusive_premium_economy_class_revenue_per_week" do
    it "is zero for a flight of zero distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 0
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      assert_in_epsilon subject.max_exclusive_premium_economy_class_revenue_per_week, 0, 0.0000001
    end

    it "increases for a longer flight" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 1
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      expect(subject.max_exclusive_premium_economy_class_revenue_per_week).to be > 0
    end

    it "stops increasing for a flight of longer distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = Calculation::MaximumRevenuePotential::PREMIUM_ECONOMY_MAX_DISTANCE
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      original_ratio_business = subject.send(:ratio_business_dollars_premium_economy)
      original_ratio_leisure = subject.send(:ratio_leisure_dollars_premium_economy)
      original_dollars = subject.max_exclusive_premium_economy_class_revenue_per_week

      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      expect(subject.max_exclusive_premium_economy_class_revenue_per_week).to be < original_dollars
      expect(subject.send(:ratio_business_dollars_premium_economy)).to eq original_ratio_business
      expect(subject.send(:ratio_leisure_dollars_premium_economy)).to eq original_ratio_leisure
    end
  end

  context "max_exclusive_business_class_revenue_per_week" do
    it "is zero for a flight of zero distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 0
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      assert_in_epsilon subject.max_exclusive_business_class_revenue_per_week, 0, 0.0000001
    end

    it "increases for a longer flight" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 1
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      expect(subject.max_exclusive_business_class_revenue_per_week).to be > 0
    end

    it "stops increasing for a flight of longer distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = Calculation::MaximumRevenuePotential::BUSINESS_MAX_DISTANCE
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      original_ratio_business = subject.send(:ratio_business_dollars_business)
      original_ratio_leisure = subject.send(:ratio_leisure_dollars_business)
      original_dollars = subject.max_exclusive_business_class_revenue_per_week

      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      expect(subject.max_exclusive_business_class_revenue_per_week).to eq original_dollars
      expect(subject.send(:ratio_business_dollars_business)).to eq original_ratio_business
      expect(subject.send(:ratio_leisure_dollars_business)).to eq original_ratio_leisure
    end
  end

  context "max_business_class_revenue_per_week" do
    it "is zero for a flight of zero distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 0
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      assert_in_epsilon subject.max_business_class_revenue_per_week, 0, 0.0000001
    end

    it "increases for a longer flight" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = 1
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      expect(subject.max_business_class_revenue_per_week).to be > 0
    end

    it "stops increasing for a flight of longer distance" do
      airport_1 = Airport.find_by(iata: "LGA")
      airport_2 = Airport.find_by(iata: "BOS")
      date = Date.today
      distance = Calculation::MaximumRevenuePotential::BUSINESS_MAX_DISTANCE
      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance)
      subject = described_class.new(airport_1, airport_2, date)

      original_ratio_business = subject.send(:ratio_business_dollars_business)
      original_ratio_leisure = subject.send(:ratio_leisure_dollars_business)
      original_dollars = subject.max_business_class_revenue_per_week

      allow(Calculation::Distance).to receive(:between_airports).with(airport_1, airport_2).and_return(distance + 1)

      expect(subject.max_business_class_revenue_per_week).to eq original_dollars
      expect(subject.send(:ratio_business_dollars_business)).to eq original_ratio_business
      expect(subject.send(:ratio_leisure_dollars_business)).to eq original_ratio_leisure
    end
  end
end
