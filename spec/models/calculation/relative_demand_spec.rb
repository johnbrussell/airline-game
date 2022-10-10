require "rails_helper"

RSpec.describe Calculation::RelativeDemand do
  context "calculate" do
    let(:origin_market) { Fabricate(:market, name: "New Haven") }
    let(:destination_market) { Fabricate(:market, name: "New York City") }
    let(:hvn) { Fabricate(:airport, iata: "HVN", market: origin_market, exclusive_catchment: 50) }
    let(:not_hvn) { Airport.new(market: origin_market, iata: "") }
    let(:lga) { Fabricate(:airport, iata: "LGA", market: destination_market, exclusive_catchment: 10) }
    let(:not_lga) { Airport.new(market: destination_market, iata: "") }
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

      described_class.new(today, hvn, lga).calculate
      actual = RelativeDemand.last

      expect(actual.origin_market_id).to eq origin_market.id
      expect(actual.origin_airport_iata).to eq "HVN"
      expect(actual.destination_market_id).to eq destination_market.id
      expect(actual.destination_airport_iata).to eq "LGA"
      expect(actual.business).to eq 5
      expect(actual.leisure).to eq 10
      expect(actual.government).to eq 1
      expect(actual.tourist).to eq 12
    end

    it "correctly calculates when only the origin airport is real" do
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, lga, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, lga, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, lga, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, jfk, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, jfk, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, jfk, today).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.new(today, hvn, not_lga).calculate
      actual = RelativeDemand.last

      expect(actual.origin_market_id).to eq origin_market.id
      expect(actual.origin_airport_iata).to eq "HVN"
      expect(actual.destination_market_id).to eq destination_market.id
      expect(actual.destination_airport_iata).to eq ""
      expect(actual.business).to eq 40
      expect(actual.leisure).to eq 80
      expect(actual.government).to eq 8
      expect(actual.tourist).to eq 96
    end

    it "correctly calculates when only the destination airport is real" do
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(lga, hvn, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, hvn, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, hvn, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, hvn, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, hvn, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, hvn, today).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.new(today, not_lga, hvn).calculate
      actual = RelativeDemand.last

      expect(actual.origin_market_id).to eq destination_market.id
      expect(actual.origin_airport_iata).to eq ""
      expect(actual.destination_market_id).to eq origin_market.id
      expect(actual.destination_airport_iata).to eq "HVN"
      expect(actual.business).to eq 40
      expect(actual.leisure).to eq 80
      expect(actual.government).to eq 8
      expect(actual.tourist).to eq 96
    end

    it "correctly calculates when no airport is real" do
      bdr = Airport.create!(market: origin_market, iata: "BDR", exclusive_catchment: 25, latitude: 9, longitude: 9, elevation: 1, runway: 1000, start_gates: 1, easy_gates: 1)
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(lga, hvn, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, hvn, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, hvn, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, hvn, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, hvn, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, hvn, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(lga, bdr, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, bdr, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, bdr, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, bdr, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, bdr, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, bdr, today).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.new(today, not_lga, not_hvn).calculate
      actual = RelativeDemand.last

      expect(actual.origin_market_id).to eq destination_market.id
      expect(actual.origin_airport_iata).to eq ""
      expect(actual.destination_market_id).to eq origin_market.id
      expect(actual.destination_airport_iata).to eq ""
      expect(actual.business).to eq 20
      expect(actual.leisure).to eq 40
      expect(actual.government).to eq 4
      expect(actual.tourist).to eq 48
    end

    it "correctly calculates when there is no shared origin catchment" do
      bdr = Airport.create!(market: origin_market, iata: "BDR", exclusive_catchment: 50, latitude: 9, longitude: 9, elevation: 1, runway: 1000, start_gates: 1, easy_gates: 1)
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, lga, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, lga, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, lga, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, jfk, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, jfk, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, jfk, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(bdr, lga, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(bdr, lga, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(bdr, lga, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(bdr, jfk, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(bdr, jfk, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(bdr, jfk, today).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.new(today, not_hvn, lga).calculate
      actual = RelativeDemand.last

      expect(actual.origin_market_id).to eq origin_market.id
      expect(actual.origin_airport_iata).to eq ""
      expect(actual.destination_market_id).to eq destination_market.id
      expect(actual.destination_airport_iata).to eq "LGA"
      expect(actual.business).to eq 0
      expect(actual.leisure).to eq 0
      expect(actual.government).to eq 0
      expect(actual.tourist).to eq 0
    end

    it "correctly calculates when there is no shared destination catchment" do
      bdr = Airport.create!(market: origin_market, iata: "BDR", exclusive_catchment: 50, latitude: 9, longitude: 9, elevation: 1, runway: 1000, start_gates: 1, easy_gates: 1)
      jfk = Airport.find_by(iata: "JFK")

      allow(Calculation::ResidentDemand).to receive(:new).with(lga, hvn, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, hvn, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, hvn, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, hvn, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, hvn, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, hvn, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(lga, bdr, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, bdr, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, bdr, today).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, bdr, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, bdr, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, bdr, today).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.new(today, not_lga, not_hvn).calculate
      actual = RelativeDemand.last

      expect(actual.origin_market_id).to eq destination_market.id
      expect(actual.origin_airport_iata).to eq ""
      expect(actual.destination_market_id).to eq origin_market.id
      expect(actual.destination_airport_iata).to eq ""
      expect(actual.business).to eq 0
      expect(actual.leisure).to eq 0
      expect(actual.government).to eq 0
      expect(actual.tourist).to eq 0
    end
  end
end
