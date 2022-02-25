require "test_helper"

class IslandableTest < ActiveSupport::TestCase
  island_airport = Airport.new
  island = Market.new(is_island: true, airports: [island_airport])

  mainland_airport = Airport.new
  mainland = Market.new(is_island: false, airports: [mainland_airport])

  test "island_to_island? returns false if neither origin nor destination is an island" do
    subject = TestClass.new(mainland_airport, mainland_airport)

    assert_not subject.send(:island_to_island?)
  end

  test "island_to_island? returns false if the origin is not an island" do
    subject = TestClass.new(mainland_airport, island_airport)

    assert_not subject.send(:island_to_island?)
  end

  test "island_to_island? returns false if the destination is not an island" do
    subject = TestClass.new(island_airport, mainland_airport)

    assert_not subject.send(:island_to_island?)
  end

  test "island_to_island? returns true if origin and destination are both islands" do
    subject = TestClass.new(island_airport, island_airport)

    assert subject.send(:island_to_island?)
  end

  test "island_to_island? returns false if origin and destination are both islands but an island exception exists" do
    IslandException.create!(market_one: island, market_two: island)
    subject = TestClass.new(island_airport, island_airport)

    assert subject.send(:island_to_island?)
  end
end

class TestClass
  include Islandable
end
