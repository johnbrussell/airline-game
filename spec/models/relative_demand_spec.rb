require "rails_helper"

RSpec.describe RelativeDemand do
  context "calculate" do
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

    it "correctly updates does not create a new record if one exists" do
      relative_demand = RelativeDemand.create!(
        origin_market_id: origin_market.id,
        destination_market_id: destination_market.id,
        origin_airport_iata: "HVN",
        destination_airport_iata: "LGA",
        business: 1,
        leisure: 1,
        government: 1,
        tourist: 1,
        pct_economy: 1,
        pct_premium_economy: 0,
        pct_business: 0,
        last_measured: today,
      )

      relative_demand_count = RelativeDemand.count

      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, lga, today).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, lga, today).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, lga, today).and_return tourist_demand

      described_class.calculate(today, hvn, lga, origin_market, destination_market)
      relative_demand.reload

      expect(relative_demand.origin_market_id).to eq origin_market.id
      expect(relative_demand.origin_airport_iata).to eq "HVN"
      expect(relative_demand.destination_market_id).to eq destination_market.id
      expect(relative_demand.destination_airport_iata).to eq "LGA"
      expect(relative_demand.business).to eq 1
      expect(relative_demand.leisure).to eq 1
      expect(relative_demand.government).to eq 1
      expect(relative_demand.tourist).to eq 1
      expect(RelativeDemand.count).to eq relative_demand_count
    end

    it "correctly calculates when both airports are real" do
      airport_population = instance_double(AirportPopulation)
      allow(AirportPopulation).to receive(:calculate).and_return(airport_population)

      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, lga, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, lga, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, lga, today, airport_population).and_return tourist_demand

      described_class.calculate(today, hvn, lga, origin_market, destination_market)
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

      airport_population = instance_double(AirportPopulation)
      allow(AirportPopulation).to receive(:calculate).and_return(airport_population)

      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, lga, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, lga, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, lga, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, jfk, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, jfk, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, jfk, today, airport_population).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.calculate(today, hvn, not_lga, origin_market, destination_market)
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

      airport_population = instance_double(AirportPopulation)
      allow(AirportPopulation).to receive(:calculate).and_return(airport_population)

      allow(Calculation::ResidentDemand).to receive(:new).with(lga, hvn, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, hvn, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, hvn, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, hvn, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, hvn, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, hvn, today, airport_population).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.calculate(today, not_lga, hvn, destination_market, origin_market)
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

      airport_population = instance_double(AirportPopulation)
      allow(AirportPopulation).to receive(:calculate).and_return(airport_population)

      allow(Calculation::ResidentDemand).to receive(:new).with(lga, hvn, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, hvn, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, hvn, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, hvn, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, hvn, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, hvn, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(lga, bdr, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, bdr, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, bdr, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, bdr, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, bdr, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, bdr, today, airport_population).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.calculate(today, not_lga, not_hvn, destination_market, origin_market)
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

      airport_population = instance_double(AirportPopulation)
      allow(AirportPopulation).to receive(:calculate).and_return(airport_population)

      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, lga, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, lga, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, lga, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(hvn, jfk, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(hvn, jfk, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(hvn, jfk, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(bdr, lga, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(bdr, lga, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(bdr, lga, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(bdr, jfk, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(bdr, jfk, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(bdr, jfk, today, airport_population).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.calculate(today, not_hvn, lga, origin_market, destination_market)
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

      airport_population = instance_double(AirportPopulation)
      allow(AirportPopulation).to receive(:calculate).and_return(airport_population)

      allow(Calculation::ResidentDemand).to receive(:new).with(lga, hvn, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, hvn, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, hvn, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, hvn, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, hvn, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, hvn, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(lga, bdr, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(lga, bdr, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(lga, bdr, today, airport_population).and_return tourist_demand
      allow(Calculation::ResidentDemand).to receive(:new).with(jfk, bdr, today, airport_population).and_return resident_demand
      allow(Calculation::GovernmentDemand).to receive(:new).with(jfk, bdr, today, airport_population).and_return government_demand
      allow(Calculation::TouristDemand).to receive(:new).with(jfk, bdr, today, airport_population).and_return tourist_demand

      origin_market.reload
      destination_market.reload

      described_class.calculate(today, not_lga, not_hvn, destination_market, origin_market)
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

  context "uniqueness validations" do
    let(:market_1) { Fabricate(:market, name: "Boston") }
    let(:market_2) { Fabricate(:market, name: "Hartford") }
    let(:market_3) { Fabricate(:market, name: "Pittsburgh") }

    it "enforce uniqueness" do
      shared_inputs = {
        business: 1,
        government: 1,
        leisure: 1,
        tourist: 1,
        pct_economy: 1,
        pct_premium_economy: 1,
        pct_business: 1,
      }

      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, last_measured: Date.today + 1, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_2.id, destination_market_id: market_1.id, last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_3.id, last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_3.id, destination_market_id: market_2.id, last_measured: Date.today, **shared_inputs)
      expect(RelativeDemand.new(origin_market_id: market_1.id, destination_market_id: market_2.id, last_measured: Date.today, **shared_inputs).save).to be false

      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", last_measured: Date.today + 1, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_2.id, destination_market_id: market_1.id, origin_airport_iata: "INU", last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_3.id, origin_airport_iata: "INU", last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_3.id, destination_market_id: market_2.id, origin_airport_iata: "INU", last_measured: Date.today, **shared_inputs)
      expect(RelativeDemand.new(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", last_measured: Date.today, **shared_inputs).save).to be false

      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", last_measured: Date.today + 1, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_2.id, destination_market_id: market_1.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_3.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_3.id, destination_market_id: market_2.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs)
      expect(RelativeDemand.new(origin_market_id: market_1.id, destination_market_id: market_2.id, origin_airport_iata: "INU", destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs).save).to be false

      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, destination_airport_iata: "FUN", last_measured: Date.today + 1, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_2.id, destination_market_id: market_1.id, destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_3.id, destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs)
      RelativeDemand.create!(origin_market_id: market_3.id, destination_market_id: market_2.id, destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs)
      expect(RelativeDemand.new(origin_market_id: market_1.id, destination_market_id: market_2.id, destination_airport_iata: "FUN", last_measured: Date.today, **shared_inputs).save).to be false
    end

    it "has nil origin_airport and destination_airport when they are not specified" do
      shared_inputs = {
        business: 1,
        government: 1,
        leisure: 1,
        tourist: 1,
        pct_economy: 1,
        pct_premium_economy: 1,
        pct_business: 1,
        last_measured: Date.today,
      }
      subject = RelativeDemand.create!(origin_market_id: market_1.id, destination_market_id: market_2.id, **shared_inputs)
      expect(subject.origin_airport).to be nil
      expect(subject.destination_airport).to be nil
    end
  end

  context "most_recent" do
    let(:market_1) { Fabricate(:market, name: "Boston") }
    let(:market_2) { Fabricate(:market, name: "Worcester") }
    let(:airport_1) { Fabricate(:airport, market: market_1) }
    let(:date) { Date.today }

    it "does not find RelativeDemands that are too old" do
      RelativeDemand.create!(
        last_measured: date - 1.year,
        origin_market: market_1,
        destination_market: market_2,
        origin_airport: airport_1,
        destination_airport_iata: "",
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
        pct_business: 0,
        pct_economy: 0,
        pct_premium_economy: 0,
      )

      expect(RelativeDemand.most_recent(date, airport_1, nil, market_1, market_2)).to be nil
    end

    it "does not find RelativeDemands that are too new" do
      RelativeDemand.create!(
        last_measured: date + 1.day,
        origin_market: market_1,
        destination_market: market_2,
        origin_airport: airport_1,
        destination_airport_iata: "",
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
        pct_business: 0,
        pct_economy: 0,
        pct_premium_economy: 0,
      )

      expect(RelativeDemand.most_recent(date, airport_1, nil, market_1, market_2)).to be nil
    end

    it "finds only RelativeDemands that meets the correct markets and airports" do
      expected = RelativeDemand.create!(
        last_measured: date,
        origin_market: market_1,
        destination_market: market_2,
        origin_airport: airport_1,
        destination_airport_iata: "",
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
        pct_business: 0,
        pct_economy: 0,
        pct_premium_economy: 0,
      )

      expect(RelativeDemand.most_recent(date, nil, airport_1, market_1, market_2)).to be nil
      expect(RelativeDemand.most_recent(date, airport_1, nil, market_2, market_1)).to be nil
      expect(RelativeDemand.most_recent(date, airport_1, nil, market_1, market_2)).to eq expected
    end

    it "maximizes by date" do
      relative_demand_1 = RelativeDemand.create!(
        last_measured: date,
        origin_market: market_1,
        destination_market: market_2,
        origin_airport: airport_1,
        destination_airport_iata: "",
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
        pct_business: 0,
        pct_economy: 0,
        pct_premium_economy: 0,
      )
      relative_demand_2 = RelativeDemand.create!(
        last_measured: date - 1.day,
        origin_market: market_1,
        destination_market: market_2,
        origin_airport: airport_1,
        destination_airport_iata: "",
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
        pct_business: 0,
        pct_economy: 0,
        pct_premium_economy: 0,
      )

      expect(RelativeDemand.most_recent(date, airport_1, nil, market_1, market_2)).to eq relative_demand_1
    end
  end

  context "most_recent_or_create" do
    let(:market_1) { Fabricate(:market, name: "Boston") }
    let(:market_2) { Fabricate(:market, name: "Worcester") }
    let(:airport_1) { Fabricate(:airport, market: market_1) }
    let(:date) { Date.today }

    it "creates a new RelativeDemand if there is none sufficiently recent" do
      relative_demand_count = RelativeDemand.count

      actual = RelativeDemand.most_recent_or_create(date, airport_1, nil, market_1, market_2)

      expect(RelativeDemand.count).to eq relative_demand_count + 1
      expect(RelativeDemand.last).to eq actual
    end

    it "returns the most recent RelativeDemand if one qualifies" do
      expected = RelativeDemand.create!(
        last_measured: date - 1.day,
        origin_market: market_1,
        destination_market: market_2,
        origin_airport: airport_1,
        destination_airport_iata: "",
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
        pct_business: 0,
        pct_economy: 0,
        pct_premium_economy: 0,
      )
      relative_demand_count = RelativeDemand.count
      actual = RelativeDemand.most_recent_or_create(date, airport_1, nil, market_1, market_2)

      expect(actual).to eq expected
      expect(RelativeDemand.count).to eq relative_demand_count
    end
  end

  context "most_recent_or_initialize" do
    let(:market_1) { Fabricate(:market, name: "Boston") }
    let(:market_2) { Fabricate(:market, name: "Worcester") }
    let(:airport_1) { Fabricate(:airport, market: market_1) }
    let(:date) { Date.today }

    it "does not create a new RelativeDemand" do
      relative_demand_count = RelativeDemand.count

      actual = RelativeDemand.most_recent_or_initialize(date, airport_1, nil, market_1, market_2)

      expect(RelativeDemand.count).to eq relative_demand_count
    end

    it "returns the most recent RelativeDemand if one qualifies" do
      expected = RelativeDemand.create!(
        last_measured: date - 1.day,
        origin_market: market_1,
        destination_market: market_2,
        origin_airport: airport_1,
        destination_airport_iata: "",
        business: 0,
        government: 0,
        leisure: 0,
        tourist: 0,
        pct_business: 0,
        pct_economy: 0,
        pct_premium_economy: 0,
      )
      relative_demand_count = RelativeDemand.count
      actual = RelativeDemand.most_recent_or_initialize(date, airport_1, nil, market_1, market_2)

      expect(actual).to eq expected
      expect(RelativeDemand.count).to eq relative_demand_count
    end
  end
end
