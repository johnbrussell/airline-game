require "test_helper"

class Calculation::DistanceTest < ActiveSupport::TestCase
  airport1 = Airport.new(latitude: -0.547458, longitude: 166.919006)
  airport2 = Airport.new(latitude: 21.317817, longitude: -157.920227)
  airport3 = Airport.new(latitude: 51.4706, longitude: -0.461941)
  market1 = Market.new(latitude: -0.547458, longitude: 166.919006)
  market2 = Market.new(latitude: 21.317817, longitude: -157.920227)
  market3 = Market.new(latitude: 51.4706, longitude: -0.461941)

  test "test equivalent points yield zero distance" do
    assert Calculation::Distance.between_airports(airport1, airport1) == 0
    assert Calculation::Distance.between_airports(airport2, airport2) == 0
  end

  test "test a moderate example" do
    expected = 2812

    assert (Calculation::Distance.between_airports(airport1, airport2) - expected).abs < 1
  end

  test "test a long example" do
    expected = 8843

    assert (Calculation::Distance.between_airports(airport1, airport3) - expected).abs < 1
  end
end
