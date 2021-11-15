require "test_helper"

class DemandableTest < ActiveSupport::TestCase
  airport1 = Airport.new(market: Market.new(country: "United States"))
  airport2 = Airport.new(market: Market.new(country: "United States"))
  airport3 = Airport.new(market: Market.new(country: "Canada", country_group: "Empire of Canada"))
  airport4 = Airport.new(market: Market.new(country: "Not Canada", country_group: "Empire of Canada"))

  test "domestic? is true when the airports are in the same country" do
    subject = TestClass.new(airport1, airport2, Date.today)

    assert subject.send(:domestic?)
  end

  test "domestic? is false when the airports are in different countries" do
    subject = TestClass.new(airport1, airport3, Date.today)

    assert_not subject.send(:domestic?)
  end

  test "same_country_group? is true when the airports are in the same country group" do
    subject = TestClass.new(airport3, airport4, Date.today)

    assert_not subject.send(:domestic?)
    assert subject.send(:same_country_group?)
  end

  test "same_country_group? is false when the airports are in different country groups" do
    subject = TestClass.new(airport1, airport3, Date.today)

    assert_not subject.send(:domestic?)
    assert_not subject.send(:same_country_group?)
  end
end

class TestClass
  include Demandable
end
