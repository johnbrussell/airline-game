require "test_helper"

class PopulatableTest < ActiveSupport::TestCase
  origin_market = Market.new(airports: [Airport.new])
  destination_market = Market.new(airports: [Airport.new(exclusive_catchment: 10), Airport.new(exclusive_catchment: 0)])

  def setup
    Market.new(
      name: "Yaren",
      income: 100000,
      is_island: true,
      is_national_capital: true,
      country: "Nauru",
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

  test "airport_population is calculated correctly" do
    Market.last.airports.create!(
      iata: "IGU",
      runway: 7000,
      elevation: 100,
      latitude: 2,
      longitude: 4,
      start_gates: 1,
      easy_gates: 1,
      exclusive_catchment: 0.5,
    )

    subject = TestClass.new(origin_market.airports.first, Market.last.airports.first, Date.today)

    assert subject.send(:airport_population) == 9950
  end

  test "available_catchment is 100 when no airports have exclusive catchment" do
    market = Market.new(airports: [Airport.new(exclusive_catchment: 0), Airport.new(exclusive_catchment: 0)])
    subject = TestClass.new(origin_market.airports.first, market.airports.last, Date.today)

    assert subject.send(:available_catchment) == 100
  end

  test "available_catchment is 100 when no other airports have exclusive_catchment" do
    subject = TestClass.new(origin_market.airports.first, destination_market.airports.first, Date.today)

    assert subject.send(:available_catchment) == 100
  end

  test "available_catchment is the catchment available to the airport" do
    subject = TestClass.new(origin_market.airports.first, destination_market.airports.last, Date.today)

    assert subject.send(:available_catchment) == 90
  end

  test "market_population is the most recent population when there is no next population" do
    nauru = Market.last

    subject = TestClass.new(origin_market.airports.first, nauru.airports.first, Date.today)

    assert subject.send(:market_population) == 10000
  end

  test "market_population is the next population when there is no previous population" do
    nauru = Market.last

    subject = TestClass.new(origin_market.airports.first, nauru.airports.first, "2009-01-01".to_date)

    assert subject.send(:market_population) == 10000
  end

  test "market_population is the current year when there is population data for the year" do
    nauru = Market.last

    nauru.populations.create!(year: 2020, population: 10500)
    nauru.populations.create!(year: 2018, population: 10100)

    subject = TestClass.new(origin_market.airports.first, nauru.airports.first, "2018-06-30".to_date)

    assert subject.send(:market_population) == 10100
  end

  test "market_population calculates the growth rate and assumes a population when no data for the year exists" do
    nauru = Market.last

    nauru.populations.create!(year: 2020, population: 10500)
    nauru.populations.create!(year: 2018, population: 10100)

    subject_2014 = TestClass.new(origin_market.airports.first, nauru.airports.first, "2014-02-02".to_date)
    subject_2019 = TestClass.new(origin_market.airports.first, nauru.airports.first, "2019-06-30".to_date)

    assert 10000 < subject_2014.send(:market_population)
    assert subject_2014.send(:market_population) < 10050
    assert 10100 < subject_2019.send(:market_population)
    assert subject_2019.send(:market_population) < 10300
  end
end

class TestClass
  include Populatable
end
