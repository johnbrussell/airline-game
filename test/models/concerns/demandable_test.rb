require "test_helper"

class DemandableTest < ActiveSupport::TestCase
  airport1 = Airport.new(market: Market.new(country: "United States"))
  airport2 = Airport.new(market: Market.new(country: "United States"))
  airport3 = Airport.new(market: Market.new(country: "Canada"))

  test "domestic? is true when the airports are in the same country" do
    subject = TestClass.new(airport1, airport2, Date.today)

    assert subject.send(:domestic?)
  end

  test "domestic? is false when the airports are in different countries" do
    subject = TestClass.new(airport1, airport3, Date.today)

    assert_not subject.send(:domestic?)
  end
end

class TestClass
  include Demandable
end
