require "rails_helper"

RSpec.describe Calculation::GovernmentDemand do
  before(:each) do
    population_1 = Population.new(
      year: 2020,
      population: 2000,
    )
    tourists_1 = Tourists.new(
      year: 1999,
      volume: 1999,
    )
    airport_1 = Airport.new(
      latitude: 6.9851,
      longitude: 158.209,
      iata: "PNI",
      elevation: 10,
      runway: 6000,
      exclusive_catchment: 5,
      start_gates: 1,
      easy_gates: 1,
    )
    Market.new(
      name: "Pohnpei",
      is_island: true,
      is_national_capital: true,
      country: "Micronesia",
      country_group: "United States",
      income: 100,
      latitude: 6.9851,
      longitude: 158.209,
      airports: [airport_1],
      populations: [population_1],
      tourists: [tourists_1],
    ).save!
    population_2 = Population.new(
      year: 2020,
      population: 1000,
    )
    tourists_2 = Tourists.new(
      year: 1999,
      volume: 1999,
    )
    airport_2 = Airport.new(
      latitude: 5.35698,
      longitude: 162.957993,
      iata: "KSA",
      elevation: 10,
      runway: 6000,
      start_gates: 1,
      easy_gates: 1,
    )
    Market.new(
      name: "Kosrae",
      is_island: true,
      country: "Micronesia",
      country_group: "United States",
      income: 100,
      latitude: 5.35698,
      longitude: 162.957993,
      airports: [airport_2],
      populations: [population_2],
      tourists: [tourists_2],
    ).save!
    population_3 = Population.new(
      year: 2020,
      population: 3000,
    )
    tourists_3 = Tourists.new(
      year: 1999,
      volume: 1999,
    )
    airport_3a = Airport.new(
      latitude: 5.35698,
      longitude: 162.957993,
      iata: "KSA2",
      elevation: 10,
      runway: 6000,
      start_gates: 1,
      easy_gates: 1,
      exclusive_catchment: 1,
    )
    airport_3b = Airport.new(
      latitude: 6,
      longitude: 164,
      iata: "southwest of KWA",
      elevation: 10,
      runway: 6000,
      start_gates: 1,
      easy_gates: 1,
      exclusive_catchment: 1
    )
    Market.new(
      name: "Micronesia",
      is_island: true,
      country: "Micronesia",
      country_group: "United States",
      income: 100,
      latitude: 5.35698,
      longitude: 162.957993,
      airports: [airport_3a, airport_3b],
      populations: [population_3],
      tourists: [tourists_3],
    ).save!
    inertia_route_service = instance_double(Calculation::InertiaRouteService, flight_cost: 10000)
    allow(Calculation::InertiaRouteService).to receive(:new).and_return(inertia_route_service)
  end

  context "demand" do
    it "is zero when origin and destination market are the same" do
      micronesia = Market.find_by!(name: "Micronesia")

      actual = Calculation::GovernmentDemand.new(micronesia.airports.first, micronesia.airports.last, Date.today).demand
      expected = 0

      assert actual == expected
    end

    it "is zero when the origin is not a national capital" do
      micronesia = Market.find_by!(name: "Micronesia")
      pohnpei = Market.find_by!(name: "Pohnpei")

      actual = Calculation::GovernmentDemand.new(micronesia.airports.first, pohnpei.airports.last, Date.today).demand
      expected = 0

      assert actual == expected
    end

    it "is zero when the origin and destination markets are rivals" do
      micronesia = Market.find_by!(name: "Micronesia")
      kosrae = Market.find_by!(name: "Kosrae")
      kosrae.update!(country_group: "Federated States of Micronesia", is_national_capital: true)
      RivalCountryGroup.create!(country_one: kosrae.country_group, country_two: micronesia.country_group)

      actual = Calculation::GovernmentDemand.new(kosrae.airports.first, micronesia.airports.last, Date.today).demand
      expected = 0

      assert actual == expected
    end

    it "is equivalent to the island demand curve when between islands, domestic, and the demand-maximizing distance" do
      pohnpei = Market.find_by!(name: "Pohnpei")
      kosrae = Market.find_by!(name: "Kosrae")

      actual = Calculation::GovernmentDemand.new(pohnpei.airports.first, kosrae.airports.first, Date.today).demand
      expected = Calculation::DemandCurve.new(:business).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * kosrae.populations.first.population

      assert_in_epsilon actual, expected, 0.000001
    end

    it "is equivalent to the normal demand curve when between islands, domestic, and the demand-maximizing distance when an island exception exists" do
      pohnpei = Market.find_by!(name: "Pohnpei")
      kosrae = Market.find_by!(name: "Kosrae")

      IslandException.create!(market_one: "Pohnpei", market_two: "Kosrae")

      actual = Calculation::GovernmentDemand.new(pohnpei.airports.first, kosrae.airports.first, Date.today).demand
      expected = Calculation::DemandCurve.new(:business).relative_demand(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * kosrae.populations.first.population / 2.0

      assert_in_epsilon actual, expected, 0.000001
    end

    it "is halved when the destination is not an island" do
      Market.find_by!(name: "Kosrae").update!(is_island: false)

      pohnpei = Market.find_by!(name: "Pohnpei")
      kosrae = Market.find_by!(name: "Kosrae")

      actual = Calculation::GovernmentDemand.new(pohnpei.airports.first, kosrae.airports.first, Date.today).demand
      expected = Calculation::DemandCurve.new(:business).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * kosrae.populations.first.population / 2.0

      assert_in_epsilon actual, expected, 0.000001
    end

    it "is halved when the origin is not an island" do
      Market.find_by!(name: "Pohnpei").update!(is_island: false)

      pohnpei = Market.find_by!(name: "Pohnpei")
      kosrae = Market.find_by!(name: "Kosrae")
      micronesia = Market.find_by!(name: "Micronesia")

      actual = Calculation::GovernmentDemand.new(pohnpei.airports.first, kosrae.airports.first, Date.today).demand
      expected = kosrae.populations.first.population / 2.0

      assert actual == expected
    end

    it "is reduced by a factor of 100 when the destination is international" do
      Market.find_by!(name: "Kosrae").update!(country: "Kosrae Republic", country_group: "Kosrae Republic")

      pohnpei = Market.find_by!(name: "Pohnpei")
      kosrae = Market.find_by!(name: "Kosrae")

      actual = Calculation::GovernmentDemand.new(pohnpei.airports.first, kosrae.airports.first, Date.today).demand
      expected = Calculation::DemandCurve.new(:business).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * kosrae.populations.first.population / 100.0

      assert_in_epsilon actual, expected, 0.000001
    end

    it "is reduced by a factor of 100/33rds when the destination is international but in the same country group" do
      Market.find_by!(name: "Kosrae").update!(country: "Kosrae Republic")

      pohnpei = Market.find_by!(name: "Pohnpei")
      kosrae = Market.find_by!(name: "Kosrae")

      actual = Calculation::GovernmentDemand.new(pohnpei.airports.first, kosrae.airports.first, Date.today).demand
      expected = Calculation::DemandCurve.new(:business).relative_demand_island(Calculation::Distance.between_airports(pohnpei.airports.first, kosrae.airports.first)) / 100.0 * 33 * kosrae.populations.first.population / 100.0

      assert_in_epsilon actual, expected, 0.000001
    end

    it "is reduced by an additional factor of 100 when the origin is not an island and the destination is international" do
      Market.find_by!(name: "Pohnpei").update!(country: "Pohnpei Republic", is_island: false, country_group: "Pohnpei Republic")

      pohnpei = Market.find_by!(name: "Pohnpei")
      kosrae = Market.find_by!(name: "Kosrae")
      micronesia = Market.find_by!(name: "Micronesia")

      actual = Calculation::GovernmentDemand.new(pohnpei.airports.first, kosrae.airports.first, Date.today).demand
      expected = 1000 / 200.0

      assert_in_epsilon actual, expected, 0.000001
    end

    it "uses the island demand curve when the origin is an island" do
      Market.find_by!(name: "Micronesia").update!(is_national_capital: true)

      micronesia = Market.find_by!(name: "Micronesia")
      kosrae = Market.find_by!(name: "Kosrae")

      subject = Calculation::GovernmentDemand.new(micronesia.airports.last, kosrae.airports.first, Date.today)

      actual = subject.demand

      assert actual > kosrae.populations.first.population
    end

    it "uses the normal demand curve when the origin is an island and the destination has an IslandException" do
      Market.find_by!(name: "Micronesia").update!(is_national_capital: true)

      micronesia = Market.find_by!(name: "Micronesia")
      kosrae = Market.find_by!(name: "Kosrae")

      IslandException.create!(market_one: "Micronesia", market_two: "Kosrae")

      subject = Calculation::GovernmentDemand.new(micronesia.airports.last, kosrae.airports.first, Date.today)

      actual = subject.demand

      assert actual < kosrae.populations.first.population
    end

    it "uses the mainland demand curve when the origin is not an island" do
      Market.find_by!(name: "Micronesia").update!(is_island: false)

      micronesia = Market.find_by!(name: "Micronesia")
      kosrae = Market.find_by!(name: "Kosrae")

      subject = Calculation::GovernmentDemand.new(micronesia.airports.last, kosrae.airports.first, Date.today)

      actual = subject.demand

      assert actual < kosrae.populations.first.population
    end
  end
end
