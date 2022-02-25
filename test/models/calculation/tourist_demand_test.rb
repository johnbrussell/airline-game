require "test_helper"

class Calculation::TouristDemandTest < ActiveSupport::TestCase
  def setup
    population_1 = Population.new(
      year: 2020,
      population: 2000,
    )
    tourists_1 = Tourists.new(
      year: 2020,
      volume: 100,
    )
    airport_1 = Airport.new(
      latitude: 6.9851,
      longitude: 158.209,
      iata: "PNI",
      elevation: 10,
      runway: 6000,
      exclusive_catchment: 0,
      start_gates: 1,
      easy_gates: 1,
    )
    Market.new(
      name: "Pohnpei",
      is_island: false,
      country: "Micronesia",
      country_group: "United States",
      income: 100,
      airports: [airport_1],
      populations: [population_1],
      tourists: [tourists_1],
    ).save!
    population_2 = Population.new(
      year: 2020,
      population: 1000,
    )
    tourists_2 = Tourists.new(
      year: 2020,
      volume: 200,
    )
    airport_2 = Airport.new(
      latitude: 5.35698,
      longitude: 162.957993,
      iata: "KSA",
      elevation: 10,
      runway: 6000,
      exclusive_catchment: 0,
      start_gates: 1,
      easy_gates: 1,
    )
    Market.new(
      name: "Kosrae",
      is_island: false,
      country: "Micronesia",
      country_group: "United States",
      income: 100,
      airports: [airport_2],
      populations: [population_2],
      tourists: [tourists_2],
    ).save!
    population_3 = Population.new(
      year: 2020,
      population: 3000,
    )
    tourists_3 = Tourists.new(
      year: 2020,
      volume: 300,
    )
    airport_3a = Airport.new(
      latitude: 5.35698,
      longitude: 162.957993,
      iata: "KSA2",
      elevation: 10,
      runway: 6000,
      exclusive_catchment: 0,
      start_gates: 1,
      easy_gates: 1,
    )
    airport_3b = Airport.new(
      latitude: 6,
      longitude: 164,
      iata: "southwest of KWA",
      elevation: 10,
      runway: 6000,
      exclusive_catchment: 0,
      start_gates: 1,
      easy_gates: 1,
    )
    Market.new(
      name: "Micronesia",
      is_island: false,
      country: "Micronesia",
      country_group: "United States",
      income: 100,
      airports: [airport_3a, airport_3b],
      populations: [population_3],
      tourists: [tourists_3],
    ).save!
  end

  test "demand is zero when origin and destination market are the same" do
    micronesia = Market.find_by!(name: "Micronesia")

    actual = Calculation::TouristDemand.new(micronesia.airports.first, micronesia.airports.last, Date.today).demand(Date.today)
    expected = 0

    assert actual == expected
  end

  test "demand is zero when the origin and destination markets are rivals" do
    micronesia = Market.find_by!(name: "Micronesia")
    kosrae = Market.find_by!(name: "Kosrae")
    kosrae.update!(country_group: "Federated States of Micronesia")
    RivalCountryGroup.create!(country_one: kosrae.country_group, country_two: micronesia.country_group)

    actual = Calculation::TouristDemand.new(micronesia.airports.first, kosrae.airports.last, Date.today).demand(Date.today)
    expected = 0

    assert actual == expected
  end

  test "demand is equivalent to the destination population when domestic and the demand-maximizing distance" do
    pohnpei = Market.find_by!(name: "Pohnpei")
    micronesia = Market.find_by!(name: "Micronesia")

    actual = Calculation::TouristDemand.new(pohnpei.airports.first, micronesia.airports.last, Date.today).demand(Date.today)
    expected = micronesia.populations.first.population

    assert actual == expected
  end

  test "demand is reduced by a factor of 3 when the destination is international" do
    Market.find_by!(name: "Micronesia").update!(country: "Federated States of Micronesia", country_group: "Federated States of Micronesia")

    pohnpei = Market.find_by!(name: "Pohnpei")
    micronesia = Market.find_by!(name: "Micronesia")

    actual = Calculation::TouristDemand.new(pohnpei.airports.first, micronesia.airports.last, Date.today).demand(Date.today)
    expected = micronesia.populations.first.population / 3.0

    assert actual == expected
  end

  test "demand is reduced by a factor of 3/2s when the destination is international but in the same country group" do
    Market.find_by!(name: "Micronesia").update!(country: "Federated States of Micronesia")

    pohnpei = Market.find_by!(name: "Pohnpei")
    micronesia = Market.find_by!(name: "Micronesia")

    actual = Calculation::TouristDemand.new(pohnpei.airports.first, micronesia.airports.last, Date.today).demand(Date.today)
    expected = micronesia.populations.first.population / 3.0 * 2

    assert actual == expected
  end

  test "demand uses the island demand curve when the origin is an island" do
    Market.find_by!(name: "Micronesia").update!(is_island: true)

    micronesia = Market.find_by!(name: "Micronesia")
    kosrae = Market.find_by!(name: "Kosrae")

    subject = Calculation::TouristDemand.new(micronesia.airports.last, kosrae.airports.first, Date.today)

    actual = subject.demand(Date.today)

    assert actual > kosrae.populations.first.population
  end

  test "demand uses the normal demand curve when the origin is an island and an island exception exists" do
    Market.find_by!(name: "Micronesia").update!(is_island: true)

    micronesia = Market.find_by!(name: "Micronesia")
    kosrae = Market.find_by!(name: "Kosrae")

    IslandException.create!(market_one: "Micronesia", market_two: "Kosrae")

    subject = Calculation::TouristDemand.new(micronesia.airports.last, kosrae.airports.first, Date.today)

    actual = subject.demand(Date.today)

    assert actual < kosrae.populations.first.population
  end

  test "demand uses the mainland demand curve when the origin is not an island" do
    Market.find_by!(name: "Kosrae").update!(is_island: true)

    micronesia = Market.find_by!(name: "Micronesia")
    kosrae = Market.find_by!(name: "Kosrae")

    subject = Calculation::TouristDemand.new(micronesia.airports.last, kosrae.airports.first, Date.today)

    actual = subject.demand(Date.today)

    assert actual < kosrae.populations.first.population
  end
end
