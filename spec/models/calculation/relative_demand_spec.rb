require "rails_helper"

RSpec.describe Calculation::RelativeDemand do
  context "business, government, leisure, and tourist" do
    let(:origin_market) { Fabricate(:market, name: "New Haven") }
    let(:destination_market) { Fabricate(:market, name: "New York City") }
    let(:hvn) { Fabricate(:airport, iata: "HVN", market: origin_market, exclusive_catchment: 50) }
    let(:not_hvn) { nil }
    let(:lga) { Fabricate(:airport, iata: "LGA", market: destination_market, exclusive_catchment: 10) }
    let(:not_lga) { nil }
    let(:today) { Date.today }
    let(:resident_demand) { instance_double(Calculation::ResidentDemand, business_demand: 100, leisure_demand: 200) }
    let(:government_demand) { instance_double(Calculation::GovernmentDemand, demand: 20) }
    let(:tourist_demand) { instance_double(Calculation::TouristDemand, demand: 240) }

    before(:each) do
      Fabricate(:airport, iata: "JFK", market: destination_market, exclusive_catchment: 10)
    end

    it "correctly calculates when both airports are real" do
      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, lga, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, lga, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, lga, today).and_return tourist_demand
      allow(Calculation::Distance).to receive(:between_airports).with(hvn, lga).and_return 50

      subject = described_class.new(today, hvn, lga, origin_market, destination_market)
      expect(subject.business).to eq 5
      expect(subject.distance).to eq 50
      expect(subject.government).to eq 1
      expect(subject.leisure).to eq 10
      expect(subject.tourist).to eq 12
    end

    it "correctly calculates when only the origin airport is real" do
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, lga, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, jfk, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, lga, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, jfk, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, lga, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, jfk, today).and_return tourist_demand
      allow(Calculation::Distance).to receive(:between_airports).with(hvn, lga).and_return 50
      allow(Calculation::Distance).to receive(:between_airports).with(hvn, jfk).and_return 70

      origin_market.reload
      destination_market.reload

      subject = described_class.new(today, hvn, not_lga, origin_market, destination_market)

      expect(subject.business).to eq 40
      expect(subject.distance).to eq 60
      expect(subject.government).to eq 8
      expect(subject.leisure).to eq 80
      expect(subject.tourist).to eq 96
    end

    it "correctly calculates when only the destination airport is real" do
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(lga, hvn, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, hvn, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, hvn, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, hvn, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, hvn, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, hvn, today).and_return tourist_demand
      allow(Calculation::Distance).to receive(:between_airports).with(lga, hvn).and_return 50
      allow(Calculation::Distance).to receive(:between_airports).with(jfk, hvn).and_return 70

      origin_market.reload
      destination_market.reload

      subject = described_class.new(today, not_lga, hvn, destination_market, origin_market)
      expect(subject.business).to eq 40
      expect(subject.distance).to eq 60
      expect(subject.government).to eq 8
      expect(subject.leisure).to eq 80
      expect(subject.tourist).to eq 96
    end

    it "correctly calculates when no airport is real" do
      bdr = Airport.create!(market: origin_market, iata: "BDR", exclusive_catchment: 25, latitude: 9, longitude: 9, elevation: 1, runway: 1000, start_gates: 1, easy_gates: 1)
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(lga, hvn, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, hvn, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(lga, bdr, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, bdr, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, hvn, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, hvn, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, bdr, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, bdr, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, hvn, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, hvn, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, bdr, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, bdr, today).and_return tourist_demand
      allow(Calculation::Distance).to receive(:between_airports).with(lga, hvn).and_return 50
      allow(Calculation::Distance).to receive(:between_airports).with(jfk, hvn).and_return 70
      allow(Calculation::Distance).to receive(:between_airports).with(lga, bdr).and_return 20
      allow(Calculation::Distance).to receive(:between_airports).with(jfk, bdr).and_return 40

      origin_market.reload
      destination_market.reload

      subject = described_class.new(today, not_lga, not_hvn, destination_market, origin_market)
      expect(subject.business).to eq 20
      expect(subject.distance).to eq 50
      expect(subject.government).to eq 4
      expect(subject.leisure).to eq 40
      expect(subject.tourist).to eq 48
    end

    it "correctly calculates when there is no shared origin catchment" do
      bdr = Airport.create!(market: origin_market, iata: "BDR", exclusive_catchment: 50, latitude: 9, longitude: 9, elevation: 1, runway: 1000, start_gates: 1, easy_gates: 1)
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, lga, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, jfk, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(bdr, lga, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(bdr, jfk, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, lga, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, jfk, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(bdr, lga, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(bdr, jfk, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, lga, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, jfk, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(bdr, lga, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(bdr, jfk, today).and_return tourist_demand
      allow(Calculation::Distance).to receive(:between_airports).with(hvn, lga).and_return 50
      allow(Calculation::Distance).to receive(:between_airports).with(hvn, jfk).and_return 70
      allow(Calculation::Distance).to receive(:between_airports).with(bdr, lga).and_return 20
      allow(Calculation::Distance).to receive(:between_airports).with(bdr, jfk).and_return 40

      origin_market.reload
      destination_market.reload

      subject = described_class.new(today, not_hvn, lga, origin_market, destination_market)
      expect(subject.business).to eq 0
      expect(subject.distance).to eq 35
      expect(subject.government).to eq 0
      expect(subject.leisure).to eq 0
      expect(subject.tourist).to eq 0
    end

    it "correctly calculates when there is no shared destination catchment" do
      bdr = Airport.create!(market: origin_market, iata: "BDR", exclusive_catchment: 50, latitude: 9, longitude: 9, elevation: 1, runway: 1000, start_gates: 1, easy_gates: 1)
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(lga, hvn, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, hvn, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(lga, bdr, today).and_return resident_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, bdr, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, hvn, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, hvn, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, bdr, today).and_return government_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, bdr, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, hvn, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, hvn, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, bdr, today).and_return tourist_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, bdr, today).and_return tourist_demand
      allow(Calculation::Distance).to receive(:between_airports).with(lga, hvn).and_return 50
      allow(Calculation::Distance).to receive(:between_airports).with(jfk, hvn).and_return 70
      allow(Calculation::Distance).to receive(:between_airports).with(lga, bdr).and_return 20
      allow(Calculation::Distance).to receive(:between_airports).with(jfk, bdr).and_return 40

      origin_market.reload
      destination_market.reload

      subject = described_class.new(today, not_lga, not_hvn, destination_market, origin_market)
      expect(subject.business).to eq 0
      expect(subject.distance).to eq 45
      expect(subject.government).to eq 0
      expect(subject.leisure).to eq 0
      expect(subject.tourist).to eq 0
    end
  end
end
