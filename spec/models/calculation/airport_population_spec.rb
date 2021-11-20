require "rails_helper"

RSpec.describe Calculation::AirportPopulation do
  before(:each) do
    Market.new(
      name: "Yaren",
      income: 100000,
      is_island: true,
      is_national_capital: true,
      country: "Nauru",
      country_group: "Nauru",
      airports: [
        Airport.new(
          iata: "INU",
          runway: 7000,
          elevation: 30,
          latitude: -1,
          longitude: -165,
          start_gates: 1,
          easy_gates: 2,
          exclusive_catchment: 0,
        )
      ],
      populations: [
        Population.new(
          year: 2010,
          population: 10000,
        )
      ]
    ).save!
  end

  context "available_catchment" do
    destination_market = Market.new(airports: [Airport.new(exclusive_catchment: 10), Airport.new(exclusive_catchment: 0)])

    it "is 100 when no airports have exclusive_catchment" do
      market = Market.new(airports: [Airport.new(exclusive_catchment: 0), Airport.new(exclusive_catchment: 0)])
      subject = described_class.new(market.airports.last, Date.today)

      expect(subject.send(:available_catchment)).to eq 100
    end

    it "is 100 when no other airports have exclusive_catchment" do
      subject = described_class.new(destination_market.airports.first, Date.today)

      assert subject.send(:available_catchment) == 100
    end

    it "is the catchment available to the airport" do
      subject = described_class.new(destination_market.airports.last, Date.today)

      assert subject.send(:available_catchment) == 90
    end
  end

  context "market_population" do
    it "is the most recent population when there is no next population" do
      nauru = Market.last

      subject = described_class.new(nauru.airports.first, Date.today)

      assert subject.send(:market_population) == 10000
    end

    it "is the next population when there is no previous population" do
      nauru = Market.last

      subject = described_class.new(nauru.airports.first, "2009-01-01".to_date)

      assert subject.send(:market_population) == 10000
    end

    it "is the current year when there is population data for the year" do
      nauru = Market.last

      nauru.populations.create!(year: 2020, population: 10500)
      nauru.populations.create!(year: 2018, population: 10100)

      subject = described_class.new(nauru.airports.first, "2018-06-30".to_date)

      assert subject.send(:market_population) == 10100
    end

    it "calculates the growth rate and assumes a population when no data for the year exists" do
      nauru = Market.last

      nauru.populations.create!(year: 2020, population: 10500)
      nauru.populations.create!(year: 2018, population: 10100)

      subject_2014 = described_class.new(nauru.airports.first, "2014-02-02".to_date)
      subject_2019 = described_class.new(nauru.airports.first, "2019-06-30".to_date)

      assert 10000 < subject_2014.send(:market_population)
      assert subject_2014.send(:market_population) < 10050
      assert 10100 < subject_2019.send(:market_population)
      assert subject_2019.send(:market_population) < 10300
    end
  end
end
