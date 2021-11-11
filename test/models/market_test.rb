require "test_helper"

class MarketTest < ActiveSupport::TestCase
  test "shared_catchment is 100 for Markets with no Airports with exclusive_catchments" do
    subject = Market.new(airports: [Airport.new(exclusive_catchment: 0), Airport.new(exclusive_catchment: 0)])

    assert subject.shared_catchment == 100
  end

  test "shared_catchment is equivalent to all non-exclusive catchment" do
    subject = Market.new(airports: [Airport.new(exclusive_catchment: 1), Airport.new(exclusive_catchment: 2.5)])

    assert subject.shared_catchment == 96.5
  end
end
