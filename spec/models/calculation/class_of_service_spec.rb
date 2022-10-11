require "rails_helper"

RSpec.describe Calculation::ClassOfService do
  let(:date) { Date.today }
  let(:market_1) { Fabricate(:market, name: "New York") }
  let(:airport_1) { Fabricate(:airport, iata: "LGA", market: market_1) }
  let(:market_2) { Fabricate(:market, name: "Boston") }
  let(:airport_2) { Fabricate(:airport, iata: "BOS", market: market_2) }

  context "ratio_business_dollars_business" do
    it "is proportional to the distance" do
      distance = Random.rand(1..2000)
      subject_1 = described_class.new(distance)
      subject_2 = described_class.new(distance * 2)
      expect(subject_2.send(:ratio_business_dollars_business) / subject_1.send(:ratio_business_dollars_business)).to eq 2
    end

    it "stops increasing when the distance exceeds BUSINESS_MAX_DISTANCE" do
      distance = Random.rand(Calculation::ClassOfService::BUSINESS_MAX_DISTANCE..10000)
      subject_1 = described_class.new(distance)
      subject_2 = described_class.new(distance * 2)
      expect(subject_2.send(:ratio_business_dollars_business)).to eq subject_1.send(:ratio_business_dollars_business)
    end
  end

  context "ratio_business_dollars_premium_economy" do
    it "is proportional to the distance" do
      distance = Random.rand(1..812)
      subject_1 = described_class.new(distance)
      subject_2 = described_class.new(distance * 2)
      expect(subject_2.send(:ratio_business_dollars_premium_economy) / subject_1.send(:ratio_business_dollars_premium_economy)).to eq 2
    end

    it "stops increasing when the distance exceeds PREMIUM_ECONOMY_MAX_DISTANCE" do
      distance = Random.rand(Calculation::ClassOfService::PREMIUM_ECONOMY_MAX_DISTANCE..10000)
      subject_1 = described_class.new(distance)
      subject_2 = described_class.new(distance * 2)
      expect(subject_2.send(:ratio_business_dollars_premium_economy)).to eq subject_1.send(:ratio_business_dollars_premium_economy)
    end
  end

  context "ratio_leisure_dollars_business" do
    it "is proportional to the distance" do
      distance = Random.rand(1..2000)
      subject_1 = described_class.new(distance)
      subject_2 = described_class.new(distance * 2)
      expect(subject_2.send(:ratio_leisure_dollars_business) / subject_1.send(:ratio_leisure_dollars_business)).to eq 2
    end

    it "stops increasing when the distance exceeds BUSINESS_MAX_DISTANCE" do
      distance = Random.rand(Calculation::ClassOfService::BUSINESS_MAX_DISTANCE..10000)
      subject_1 = described_class.new(distance)
      subject_2 = described_class.new(distance * 2)
      expect(subject_2.send(:ratio_leisure_dollars_business)).to eq subject_1.send(:ratio_leisure_dollars_business)
    end
  end

  context "ratio_leisure_dollars_premium_economy" do
    it "is proportional to the distance" do
      distance = Random.rand(1..812)
      subject_1 = described_class.new(distance)
      subject_2 = described_class.new(distance * 2)
      expect(subject_2.send(:ratio_leisure_dollars_premium_economy) / subject_1.send(:ratio_leisure_dollars_premium_economy)).to eq 2
    end

    it "stops increasing when the distance exceeds PREMIUM_ECONOMY_MAX_DISTANCE" do
      distance = Random.rand(Calculation::ClassOfService::PREMIUM_ECONOMY_MAX_DISTANCE..10000)
      subject_1 = described_class.new(distance)
      subject_2 = described_class.new(distance * 2)
      expect(subject_2.send(:ratio_leisure_dollars_premium_economy)).to eq subject_1.send(:ratio_leisure_dollars_premium_economy)
    end
  end

  context "pct_business_dollars_business" do
    it "is equal to the percentage of the business dollars allocated to business class" do
      distance = Calculation::ClassOfService::BUSINESS_MAX_DISTANCE + 1
      expected_ratio_sum = 2 + 0.75 + 1

      subject = described_class.new(distance)
      expect(subject.pct_business_dollars_business).to eq 2 / expected_ratio_sum
    end
  end

  context "pct_business_dollars_premium_economy" do
    it "is equal to the percentage of the business dollars allocated to business class" do
      distance = Calculation::ClassOfService::BUSINESS_MAX_DISTANCE + 1
      expected_ratio_sum = 2 + 0.75 + 1

      subject = described_class.new(distance)
      expect(subject.pct_business_dollars_premium_economy).to eq 0.75 / expected_ratio_sum
    end
  end

  context "pct_business_dollars_economy" do
    it "is equal to the percentage of the business dollars allocated to business class" do
      distance = Calculation::ClassOfService::BUSINESS_MAX_DISTANCE + 1
      expected_ratio_sum = 2 + 0.75 + 1

      subject = described_class.new(distance)
      expect(subject.pct_business_dollars_economy).to eq 1 / expected_ratio_sum
    end
  end

  context "pct_leisure_dollars_business" do
    it "is equal to the percentage of the business dollars allocated to business class" do
      distance = Calculation::ClassOfService::BUSINESS_MAX_DISTANCE + 1
      expected_ratio_sum = 0.5 + 0.25 + 1

      subject = described_class.new(distance)
      expect(subject.pct_leisure_dollars_business).to eq 0.5 / expected_ratio_sum
    end
  end

  context "pct_leisure_dollars_premium_economy" do
    it "is equal to the percentage of the business dollars allocated to business class" do
      distance = Calculation::ClassOfService::BUSINESS_MAX_DISTANCE + 1
      expected_ratio_sum = 0.5 + 0.25 + 1

      subject = described_class.new(distance)
      expect(subject.pct_leisure_dollars_premium_economy).to eq 0.25 / expected_ratio_sum
    end
  end

  context "pct_leisure_dollars_economy" do
    it "is equal to the percentage of the business dollars allocated to business class" do
      distance = Calculation::ClassOfService::BUSINESS_MAX_DISTANCE + 1
      expected_ratio_sum = 0.5 + 0.25 + 1

      subject = described_class.new(distance)
      expect(subject.pct_leisure_dollars_economy).to eq 1 / expected_ratio_sum
    end
  end
end
