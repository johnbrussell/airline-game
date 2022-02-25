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
      ],
      tourists: [
        Tourists.new(
          year: 1920,
          volume: 25,
        )
      ],
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

    assert subject.send(:airport_population, Date.today) == 9950
  end
end

class TestClass
  include Populatable
end
