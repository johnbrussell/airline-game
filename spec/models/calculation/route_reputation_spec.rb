require "rails_helper"

RSpec.describe Calculation::RouteReputation do
  let(:airline_1) { Airline.new(id: 1) }
  let(:airline_2) { Airline.new(id: 2) }
  let(:airline_3) { Airline.new(id: 3) }
  let(:airline_4) { Airline.new(id: 4) }
  let(:reputation_data_1) { Calculation::ReputationData.new(airline_1, 100, 1, AirlineRoute::MIN_SERVICE_QUALITY, 0) }
  let(:reputation_data_2) { Calculation::ReputationData.new(airline_2, 100, 1, AirlineRoute::MIN_SERVICE_QUALITY, 0) }
  let(:reputation_data_3) { Calculation::ReputationData.new(airline_3, 100, 1, AirlineRoute::MIN_SERVICE_QUALITY, 0) }
  let(:reputation_data_4) { Calculation::ReputationData.new(airline_4, 100, 1, AirlineRoute::MIN_SERVICE_QUALITY, 0) }
  let(:all_reputation_data) { [reputation_data_1, reputation_data_2, reputation_data_3, reputation_data_4] }

  context "reputation" do
    it "calculates correctly when every reputation data point has a minimal reputation" do
      all_reputation_data = [reputation_data_1, reputation_data_2, reputation_data_3, reputation_data_4]
      all_reputation_data.each do |rd|
        expect(Calculation::RouteReputation.new(rd, all_reputation_data).reputation).to eq Calculation::RouteReputation::MIN_REPUTATION
      end
    end

    it "calculates fare reputation correctly" do
      all_reputation_data[0].fare = 50

      assert_in_epsilon Calculation::RouteReputation.new(all_reputation_data[0], all_reputation_data).reputation, (1 - Calculation::RouteReputation::REPUTATION_WEIGHTS[:fare]) * 1 + Calculation::RouteReputation::REPUTATION_WEIGHTS[:fare] * 3.25, 0.000001

      (1..3).each do |i|
        expect(Calculation::RouteReputation.new(all_reputation_data[i], all_reputation_data).reputation).to eq 1
      end
    end

    it "calculates frequency reputation correctly when each reputation data point is a different airline" do
      all_reputation_data[0].frequencies = Calculation::RouteReputation::FREQUENCIES_FOR_MAX_REPUTATION * 2

      assert_in_epsilon Calculation::RouteReputation.new(all_reputation_data[0], all_reputation_data).reputation, (1 - Calculation::RouteReputation::REPUTATION_WEIGHTS[:frequency]) * 1 + Calculation::RouteReputation::REPUTATION_WEIGHTS[:frequency] * Calculation::RouteReputation::MAX_REPUTATION, 0.000001

      (1..3).each do |i|
        expect(Calculation::RouteReputation.new(all_reputation_data[i], all_reputation_data).reputation).to eq 1
      end
    end

    it "calculates frequency reputation correctly when each reputation point is a different airline and frequencies are less than the maximum reputation" do
      all_reputation_data[0].frequencies = Calculation::RouteReputation::FREQUENCIES_FOR_MAX_REPUTATION / 2.0 + 1 / 2.0

      assert_in_epsilon Calculation::RouteReputation.new(all_reputation_data[0], all_reputation_data).reputation, 1 + Calculation::RouteReputation::REPUTATION_WEIGHTS[:frequency] * (Calculation::RouteReputation::MAX_REPUTATION - Calculation::RouteReputation::MIN_REPUTATION) / 2, 0.000001

      (1..3).each do |i|
        expect(Calculation::RouteReputation.new(all_reputation_data[i], all_reputation_data).reputation).to eq 1
      end
    end

    it "calculates frequency reputation correctly when each reputation data point is a different airline" do
      all_reputation_data[0].airline = all_reputation_data[1].airline
      all_reputation_data[0].frequencies = Calculation::RouteReputation::FREQUENCIES_FOR_MAX_REPUTATION / 2.0 + 1 / 2.0
      all_reputation_data[1].frequencies = Calculation::RouteReputation::FREQUENCIES_FOR_MAX_REPUTATION / 2.0 + 1 / 2.0

      assert_in_epsilon Calculation::RouteReputation.new(all_reputation_data[0], all_reputation_data).reputation, (1 - Calculation::RouteReputation::REPUTATION_WEIGHTS[:frequency]) * 1 + Calculation::RouteReputation::REPUTATION_WEIGHTS[:frequency] * Calculation::RouteReputation::MAX_REPUTATION, 0.000001
      assert_in_epsilon Calculation::RouteReputation.new(all_reputation_data[1], all_reputation_data).reputation, (1 - Calculation::RouteReputation::REPUTATION_WEIGHTS[:frequency]) * 1 + Calculation::RouteReputation::REPUTATION_WEIGHTS[:frequency] * Calculation::RouteReputation::MAX_REPUTATION, 0.000001

      (2..3).each do |i|
        expect(Calculation::RouteReputation.new(all_reputation_data[i], all_reputation_data).reputation).to eq 1
      end
    end

    it "calculates ifs reputation correctly" do
      all_reputation_data[0].ifs = AirlineRoute::MAX_SERVICE_QUALITY

      assert_in_epsilon Calculation::RouteReputation.new(all_reputation_data[0], all_reputation_data).reputation, (1 - Calculation::RouteReputation::REPUTATION_WEIGHTS[:ifs]) * 1 + Calculation::RouteReputation::REPUTATION_WEIGHTS[:ifs] * Calculation::RouteReputation::MAX_REPUTATION, 0.000001

      (1..3).each do |i|
        expect(Calculation::RouteReputation.new(all_reputation_data[i], all_reputation_data).reputation).to eq 1
      end
    end

    it "calculates legroom reputation correctly" do
      all_reputation_data[0].legroom = 1

      assert_in_epsilon Calculation::RouteReputation.new(all_reputation_data[0], all_reputation_data).reputation, (1 - Calculation::RouteReputation::REPUTATION_WEIGHTS[:legroom]) * 1 + Calculation::RouteReputation::REPUTATION_WEIGHTS[:legroom] * Calculation::RouteReputation::MAX_REPUTATION, 0.000001

      (1..3).each do |i|
        expect(Calculation::RouteReputation.new(all_reputation_data[i], all_reputation_data).reputation).to eq 1
      end
    end
  end
end
