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
      latitude: -1,
      longitude: -165,
      airports: [
        Airport.new(
          iata: "INU",
          runway: 7000,
          elevation: 30,
          latitude: -1,
          longitude: -165,
          start_gates: 1,
          easy_gates: 2,
          exclusive_catchment: 5,
        )
      ],
      populations: [
        Population.new(
          year: 2010,
          population: 10000,
        )
      ],
      tourists: [
        Tourists.new(
          year: 2010,
          volume: 100000,
        )
      ],
    ).save!
  end

  context "available_catchment" do
    destination_market = Market.new(airports: [Airport.new(exclusive_catchment: 15), Airport.new(exclusive_catchment: 10)])

    it "is the catchment available to the airport" do
      subject = described_class.new(destination_market.airports.last, Date.today)

      expect(subject.send(:available_catchment)).to eq 85
    end
  end

  context "government_workers" do
    it "is 0 when the market is not a national capital" do
      nauru = Market.last
      nauru.update!(is_national_capital: false)

      subject = described_class.new(nauru.airports.first, Date.today)

      expect(subject.government_workers).to eq 0
    end

    it "is CAPITAL_GOVERNMENT_WORKERS when the market is a national capital" do
      nauru = Market.last

      subject = described_class.new(nauru.airports.first, "2009-01-01".to_date)

      expect(subject.government_workers).to eq described_class::CAPITAL_GOVERNMENT_WORKERS
    end

    it "scales for different catchment sizes" do
      nauru = Market.last
      Airport.create!(market: nauru, iata: "FOO", exclusive_catchment: 20, runway: 100, latitude: 10, longitude: 10, start_gates: 1, easy_gates: 1, elevation: -100)
      nauru.reload

      subject_inu = described_class.new(nauru.airports.first, Date.today)
      subject_foo = described_class.new(nauru.airports.last, Date.today)

      expect(subject_inu.government_workers).to eq 8000
      expect(subject_foo.government_workers).to eq 9500
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

  context "market_tourists" do
    it "is the most recent tourists when there is no next tourists" do
      nauru = Market.last

      subject = described_class.new(nauru.airports.first, Date.today)

      assert subject.send(:market_tourists) == 100000
    end

    it "is the next tourists when there is no previous tourists" do
      nauru = Market.last

      subject = described_class.new(nauru.airports.first, "2009-01-01".to_date)

      assert subject.send(:market_tourists) == 100000
    end

    it "is the current year when there is tourists data for the year" do
      nauru = Market.last

      nauru.tourists.create!(year: 2020, volume: 105000)
      nauru.tourists.create!(year: 2018, volume: 101000)

      subject = described_class.new(nauru.airports.first, "2018-06-30".to_date)

      assert subject.send(:market_tourists) == 101000
    end

    it "calculates the growth rate and assumes a tourists when no data for the year exists" do
      nauru = Market.last

      nauru.tourists.create!(year: 2020, volume: 105000)
      nauru.tourists.create!(year: 2018, volume: 101000)

      subject_2014 = described_class.new(nauru.airports.first, "2014-02-02".to_date)
      subject_2019 = described_class.new(nauru.airports.first, "2019-06-30".to_date)

      assert 100000 < subject_2014.send(:market_tourists)
      assert subject_2014.send(:market_tourists) < 100500
      assert 101000 < subject_2019.send(:market_tourists)
      assert subject_2019.send(:market_tourists) < 103000
    end
  end
end
