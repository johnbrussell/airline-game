require "test_helper"

class Calculation::ResidentDemandTest < ActiveSupport::TestCase
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
      is_island: true,
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
      is_island: true,
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
      is_island: true,
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

    actual_business = Calculation::ResidentDemand.new(micronesia.airports.first, micronesia.airports.last).business_demand(Date.today)
    actual_leisure = Calculation::ResidentDemand.new(micronesia.airports.first, micronesia.airports.last).leisure_demand(Date.today)
    expected = 0

    assert actual_business == expected
    assert actual_leisure == expected
  end

  test "demand is zero when the origin and destination markets are rivals" do
    micronesia = Market.find_by!(name: "Micronesia")
    kosrae = Market.find_by!(name: "Kosrae")
    kosrae.update!(country_group: "Federated States of Micronesia")
    RivalCountryGroup.create!(country_one: kosrae.country_group, country_two: micronesia.country_group)

    actual_business = Calculation::ResidentDemand.new(micronesia.airports.first, kosrae.airports.last).business_demand(Date.today)
    actual_leisure = Calculation::ResidentDemand.new(micronesia.airports.first, kosrae.airports.last).leisure_demand(Date.today)
    expected = 0

    assert actual_business == expected
    assert actual_leisure == expected
  end

  test "business demand is equivalent to the island demand curve when between islands, domestic, and the demand-maximizing distance" do
    pohnpei = Market.find_by!(name: "Pohnpei")
    kosrae = Market.find_by!(name: "Kosrae")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, kosrae.airports.first).business_demand(Date.today)
    expected = Calculation::DemandCurve.new(:business).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * kosrae.populations.first.population

    assert_in_epsilon actual, expected, 0.000001
  end

  test "business demand is equivalent to the normal demand curve when between islands, domestic, and the demand-maximizing distance and an island exception exists" do
    pohnpei = Market.find_by!(name: "Pohnpei")
    kosrae = Market.find_by!(name: "Kosrae")

    IslandException.create!(market_one: "Pohnpei", market_two: "Kosrae")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, kosrae.airports.first).business_demand(Date.today)
    expected = Calculation::DemandCurve.new(:business).relative_demand(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * kosrae.populations.first.population / 2.0

    assert_in_epsilon actual, expected, 0.000001
  end

  test "leisure demand is equivalent to the island demand curve when between islands, domestic, and the demand-maximizing distance" do
    pohnpei = Market.find_by!(name: "Pohnpei")
    micronesia = Market.find_by!(name: "Micronesia")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, micronesia.airports.last).leisure_demand(Date.today)
    expected = Calculation::DemandCurve.new(:leisure).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, micronesia.airports.last)) / 100.0 * micronesia.populations.first.population

    assert_in_epsilon actual, expected, 0.000001
  end

  test "leisure demand is equivalent to the normal demand curve when between islands, domestic, and the demand-maximizing distance and an island exception exists" do
    pohnpei = Market.find_by!(name: "Pohnpei")
    micronesia = Market.find_by!(name: "Micronesia")

    IslandException.create!(market_one: "Pohnpei", market_two: "Micronesia")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, micronesia.airports.last).leisure_demand(Date.today)
    expected = Calculation::DemandCurve.new(:leisure).relative_demand(Calculation::Distance.between_airports(pohnpei.airports.first, micronesia.airports.last)) / 100.0 * micronesia.populations.first.population / 2.0

    assert_in_epsilon actual, expected, 0.000001
  end

  test "business demand is halved when the destination is not an island" do
    Market.find_by!(name: "Kosrae").update!(is_island: false)

    pohnpei = Market.find_by!(name: "Pohnpei")
    kosrae = Market.find_by!(name: "Kosrae")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, kosrae.airports.first).business_demand(Date.today)
    expected = Calculation::DemandCurve.new(:business).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * kosrae.populations.first.population / 2.0

    assert_in_epsilon actual, expected, 0.000001
  end

  test "leisure demand is halved when the destination is not an island" do
    Market.find_by!(name: "Micronesia").update!(is_island: false)

    pohnpei = Market.find_by!(name: "Pohnpei")
    micronesia = Market.find_by!(name: "Micronesia")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, micronesia.airports.last).leisure_demand(Date.today)
    expected = Calculation::DemandCurve.new(:leisure).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, micronesia.airports.last)) / 100.0 * micronesia.populations.first.population / 2.0

    assert_in_epsilon actual, expected, 0.000001
  end

  test "demand is halved when the origin is not an island" do
    Market.find_by!(name: "Pohnpei").update!(is_island: false)

    pohnpei = Market.find_by!(name: "Pohnpei")
    kosrae = Market.find_by!(name: "Kosrae")
    micronesia = Market.find_by!(name: "Micronesia")

    actual_business = Calculation::ResidentDemand.new(pohnpei.airports.first, kosrae.airports.first).business_demand(Date.today)
    expected_business = kosrae.populations.first.population / 2.0

    actual_leisure = Calculation::ResidentDemand.new(pohnpei.airports.first, micronesia.airports.last).leisure_demand(Date.today)
    expected_leisure = micronesia.populations.first.population / 2.0

    assert actual_business == expected_business
    assert actual_leisure == expected_leisure
  end

  test "business demand is reduced by a factor of 12 when the origin is an island and the destination is international" do
    Market.find_by!(name: "Kosrae").update!(country: "Kosrae Republic", country_group: "Kosrae Republic")

    pohnpei = Market.find_by!(name: "Pohnpei")
    kosrae = Market.find_by!(name: "Kosrae")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, kosrae.airports.first).business_demand(Date.today)
    expected = Calculation::DemandCurve.new(:business).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * kosrae.populations.first.population / 12.0

    assert_in_epsilon actual, expected, 0.000001
  end

  test "business demand is reduced by a factor of 4/3rds when the origin is an island and the destination is international but in the same country group" do
    Market.find_by!(name: "Kosrae").update!(country: "Kosrae Republic")

    pohnpei = Market.find_by!(name: "Pohnpei")
    kosrae = Market.find_by!(name: "Kosrae")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, kosrae.airports.first).business_demand(Date.today)
    expected = Calculation::DemandCurve.new(:business).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * kosrae.populations.first.population / 12.0 * 9

    assert_in_epsilon actual, expected, 0.000001
  end

  test "leisure demand is reduced by a factor of 12 when the origin is an island and the destination is international" do
    Market.find_by!(name: "Micronesia").update!(country: "Federated States of Micronesia", country_group: "Federated States of Micronesia")

    pohnpei = Market.find_by!(name: "Pohnpei")
    micronesia = Market.find_by!(name: "Micronesia")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, micronesia.airports.last).leisure_demand(Date.today)
    expected = Calculation::DemandCurve.new(:leisure).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, micronesia.airports.last)) / 100.0 * micronesia.populations.first.population / 12.0

    assert_in_epsilon actual, expected, 0.000001
  end

  test "leisure demand is reduced by a factor of 4/3rds when the origin is an island and the destination is international but in the same country group" do
    Market.find_by!(name: "Micronesia").update!(country: "Federated States of Micronesia")

    pohnpei = Market.find_by!(name: "Pohnpei")
    micronesia = Market.find_by!(name: "Micronesia")

    actual = Calculation::ResidentDemand.new(pohnpei.airports.first, micronesia.airports.last).leisure_demand(Date.today)
    expected = Calculation::DemandCurve.new(:leisure).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, micronesia.airports.last)) / 100.0 * micronesia.populations.first.population / 12.0 * 9

    assert_in_epsilon actual, expected, 0.000001
  end

  test "demand is reduced by an additional factor of 4 when the origin is not an island and the destination is international" do
    Market.find_by!(name: "Pohnpei").update!(country: "Pohnpei Republic", is_island: false, country_group: "Pohnpei Republic")

    pohnpei = Market.find_by!(name: "Pohnpei")
    kosrae = Market.find_by!(name: "Kosrae")
    micronesia = Market.find_by!(name: "Micronesia")

    actual_business = Calculation::ResidentDemand.new(pohnpei.airports.first, kosrae.airports.first).business_demand(Date.today)
    expected_business = 1000 / 8.0

    actual_leisure = Calculation::ResidentDemand.new(pohnpei.airports.first, micronesia.airports.last).leisure_demand(Date.today)
    expected_leisure = micronesia.populations.first.population / 8.0

    assert actual_business == expected_business
    assert actual_leisure == expected_leisure
  end

  test "demand is reduced by an additional factor of 4/3rds when the origin is not an island and the destination is international but in the same country group" do
    Market.find_by!(name: "Pohnpei").update!(country: "Pohnpei Republic", is_island: false)

    pohnpei = Market.find_by!(name: "Pohnpei")
    kosrae = Market.find_by!(name: "Kosrae")
    micronesia = Market.find_by!(name: "Micronesia")

    actual_business = Calculation::ResidentDemand.new(pohnpei.airports.first, kosrae.airports.first).business_demand(Date.today)
    expected_business = 1000 / 8.0 * 3

    actual_leisure = Calculation::ResidentDemand.new(pohnpei.airports.first, micronesia.airports.last).leisure_demand(Date.today)
    expected_leisure = micronesia.populations.first.population / 8.0 * 3

    assert actual_business == expected_business
    assert actual_leisure == expected_leisure
  end

  test "demand uses the island demand curve when the origin is an island" do
    micronesia = Market.find_by!(name: "Micronesia")
    kosrae = Market.find_by!(name: "Kosrae")

    subject = Calculation::ResidentDemand.new(micronesia.airports.last, kosrae.airports.first)

    actual_business = subject.business_demand(Date.today)
    actual_leisure = subject.leisure_demand(Date.today)

    assert actual_business > kosrae.populations.first.population
    assert actual_leisure > kosrae.populations.first.population
  end

  test "demand uses the mainland demand curve when the origin is not an island" do
    Market.find_by!(name: "Micronesia").update!(is_island: false)

    micronesia = Market.find_by!(name: "Micronesia")
    kosrae = Market.find_by!(name: "Kosrae")

    subject = Calculation::ResidentDemand.new(micronesia.airports.last, kosrae.airports.first)

    actual_business = subject.business_demand(Date.today)
    actual_leisure = subject.leisure_demand(Date.today)

    assert actual_business < kosrae.populations.first.population
    assert actual_leisure < kosrae.populations.first.population
  end
end
