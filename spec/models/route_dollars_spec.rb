require "rails_helper"

RSpec.describe RouteDollars do
  context "between_markets" do
    let(:market_1) { Fabricate(:market, name: "Fiji") }
    let(:market_2) { Fabricate(:market, name: "Nauru") }
    let(:date) { Date.today }
    let(:route_dollars_calculator) { instance_double(Calculation::RouteDollars, business_class_dollars: 10, economy_class_dollars: 20, premium_economy_class_dollars: 5, distance: 1000) }

    let(:airport_1) { Fabricate(:airport, iata: "NAN", market: market_1, exclusive_catchment: 10) }
    let(:airport_2) { Fabricate(:airport, iata: "SUV", market: market_1, exclusive_catchment: 10) }
    let(:airport_3) { Fabricate(:airport, iata: "INU", market: market_2, exclusive_catchment: 10) }

    it "calculates all of the RouteDollars in each direction between the two markets only when they do not exist" do
      route_dollars_count = RouteDollars.count

      expected_increase_in_route_dollars_count = (1 + 1) * (2 + 1)

      expect(RelativeDemand).to receive(:calculate_between_markets).with(date, market_1, market_2).exactly(6).times
      expect(RelativeDemand).to receive(:calculate_between_markets).with(date, market_2, market_1).exactly(6).times
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_1, market_2, airport_1, airport_3).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_2, market_1, airport_3, airport_1).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_1, market_2, airport_2, airport_3).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_2, market_1, airport_3, airport_2).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_1, market_2, nil, airport_3).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_2, market_1, airport_3, nil).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_1, market_2, airport_1, nil).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_2, market_1, nil, airport_1).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_1, market_2, airport_2, nil).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_2, market_1, nil, airport_2).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_1, market_2, nil, nil).and_return(route_dollars_calculator)
      expect(Calculation::RouteDollars).to receive(:new).with(date, market_2, market_1, nil, nil).and_return(route_dollars_calculator)

      market_1.reload
      market_2.reload

      actual = RouteDollars.between_markets(market_1, market_2, date)

      expect(RouteDollars.count).to eq route_dollars_count + expected_increase_in_route_dollars_count
      expect(RouteDollars.last.business).to eq 20 / RouteDollars::WEEKS_PER_YEAR
      expect(RouteDollars.last.economy).to eq 40 / RouteDollars::WEEKS_PER_YEAR
      expect(RouteDollars.last.premium_economy).to eq 10 / RouteDollars::WEEKS_PER_YEAR
      expect(actual.length).to eq expected_increase_in_route_dollars_count

      actual_2 = RouteDollars.between_markets(market_2, market_1, date)
      expect(actual_2.length).to eq expected_increase_in_route_dollars_count
      expect(RouteDollars.count).to eq route_dollars_count + expected_increase_in_route_dollars_count

      actual_3 = RouteDollars.between_markets(market_1, market_2, date)
      expect(actual_3.length).to eq expected_increase_in_route_dollars_count
      expect(RouteDollars.count).to eq route_dollars_count + expected_increase_in_route_dollars_count
    end
  end

  context "calculate" do
    let(:market_1) { Fabricate(:market, name: "Altoona") }
    let(:market_2) { Fabricate(:market, name: "Johnstown") }
    let(:date) { Date.today }

    it "calcuates a new RouteDollars if none exists" do
      route_dollars_count = RouteDollars.count

      route_dollars_calculator_1 = instance_double(Calculation::RouteDollars, business_class_dollars: 1, economy_class_dollars: 2, premium_economy_class_dollars: 3, distance: 4)
      route_dollars_calculator_2 = instance_double(Calculation::RouteDollars, business_class_dollars: 2, economy_class_dollars: 4, premium_economy_class_dollars: 6, distance: 4)
      allow(Calculation::RouteDollars).to receive(:new).with(date, market_1, market_2, nil, nil).and_return(route_dollars_calculator_1)
      allow(Calculation::RouteDollars).to receive(:new).with(date, market_2, market_1, nil, nil).and_return(route_dollars_calculator_2)

      expect(RelativeDemand).to receive(:calculate_between_markets).with(date, market_1, market_2)
      expect(RelativeDemand).to receive(:calculate_between_markets).with(date, market_2, market_1)

      actual = RouteDollars.calculate(date, market_1, market_2, nil, nil)

      expect(RouteDollars.count).to eq route_dollars_count + 1
      expect(actual.date).to eq date
      expect(actual.distance).to eq 4
      expect(actual.business).to eq 3 / RouteDollars::WEEKS_PER_YEAR
      expect(actual.economy).to eq 6 / RouteDollars::WEEKS_PER_YEAR
      expect(actual.premium_economy).to eq 9 / RouteDollars::WEEKS_PER_YEAR
      expect(actual.origin_airport_iata).to eq ""
      expect(actual.destination_airport_iata).to eq ""
    end

    it "uses the last valid RouteDollars if one exists" do
      RouteDollars.create!(
        origin_market: market_1,
        destination_market: market_2,
        origin_airport_iata: "",
        destination_airport_iata: "",
        date: date,
        distance: 0,
        business: 1,
        economy: 2,
        premium_economy: 3,
      )

      route_dollars_count = RouteDollars.count

      expect(RelativeDemand).not_to receive(:calculate_between_markets)

      actual = RouteDollars.calculate(date, market_1, market_2, nil, nil)

      expect(RouteDollars.count).to eq route_dollars_count
      expect(actual.date).to eq date
      expect(actual.distance).to eq 0
      expect(actual.business).to eq 1
      expect(actual.economy).to eq 2
      expect(actual.premium_economy).to eq 3
      expect(actual.origin_airport_iata).to eq ""
      expect(actual.destination_airport_iata).to eq ""
    end
  end

  context "display_revenues_between_airports" do
    let(:date) { Date.today }
    let(:origin_market) { Fabricate(:market, name: "Nauru") }
    let(:destination_market) { Fabricate(:market, name: "Tuvalu") }
    let(:airport_1) { Fabricate(:airport, iata: "INU", market: origin_market) }
    let(:airport_2) { Fabricate(:airport, iata: "FUN", market: destination_market) }

    before(:each) do
      RouteDollars.create!(origin_market: origin_market, destination_market: destination_market, origin_airport_iata: "", destination_airport_iata: "", date: date, distance: 1, business: 2, economy: 4, premium_economy: 5)
      RouteDollars.create!(origin_market: origin_market, destination_market: destination_market, origin_airport_iata: "", destination_airport_iata: "FUN", date: date, distance: 1, business: 2, economy: 4, premium_economy: 5)
      RouteDollars.create!(origin_market: origin_market, destination_market: destination_market, origin_airport_iata: "", destination_airport_iata: "TUV", date: date, distance: 1, business: 2, economy: 4, premium_economy: 5)
      RouteDollars.create!(origin_market: origin_market, destination_market: destination_market, origin_airport_iata: "INU", destination_airport_iata: "", date: date, distance: 1, business: 2, economy: 4, premium_economy: 5)
      RouteDollars.create!(origin_market: origin_market, destination_market: destination_market, origin_airport_iata: "INU", destination_airport_iata: "FUN", date: date, distance: 1, business: 2, economy: 4, premium_economy: 5)
      RouteDollars.create!(origin_market: origin_market, destination_market: destination_market, origin_airport_iata: "INU", destination_airport_iata: "TUV", date: date, distance: 1, business: 2, economy: 4, premium_economy: 5)
      RouteDollars.create!(origin_market: origin_market, destination_market: destination_market, origin_airport_iata: "NRU", destination_airport_iata: "", date: date, distance: 1, business: 2, economy: 4, premium_economy: 5)
      RouteDollars.create!(origin_market: origin_market, destination_market: destination_market, origin_airport_iata: "NRU", destination_airport_iata: "FUN", date: date, distance: 1, business: 2, economy: 4, premium_economy: 5)
      RouteDollars.create!(origin_market: origin_market, destination_market: destination_market, origin_airport_iata: "NRU", destination_airport_iata: "TUV", date: date, distance: 1, business: 2, economy: 4, premium_economy: 5)
    end

    it "calculates correctly" do
      expected = {
        :business => 8,
        :economy => 16,
        :premium_economy => 20,
      }

      expect(RouteDollars.display_revenues_between_airports(airport_1, airport_2, date)).to eq expected
      expect(RouteDollars.display_revenues_between_airports(airport_2, airport_1, date)).to eq expected
    end
  end

  context "markets_alphabetized" do
    let(:market_1) { Fabricate(:market, name: "Boston") }
    let(:market_2) { Fabricate(:market, name: "Bostonia") }

    it "fails to validate when the origin market name is alphabetically after the destination market's name" do
      subject = RouteDollars.new(origin_market: market_2, destination_market: market_1)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Origin market name must be alphabetically before destination_market name"
    end
  end
end
