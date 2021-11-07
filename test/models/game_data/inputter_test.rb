require "test_helper"

class GameData::InputterTest < ActiveSupport::TestCase
  def setup
    Market.new(name: "Yaren", income: 100000, is_island: true, is_national_capital: true, country: "Nauru").save!
  end

  test "new Markets created" do
    data_point = {
      "Metro Area" => "Funafuti",
      "Country" => "Tuvalu",
      "Income" => 40000,
      "isNationalCapital" => "yes",
      "isIsland" => "yes",
    }

    GameData::Inputter.send(:create_or_update_market, data_point)

    assert_equal(Market.count, 2)

    last_market = Market.last

    assert_equal(last_market.name, "Funafuti")
    assert_equal(last_market.country, "Tuvalu")
    assert_equal(last_market.income, 40000)
    assert_equal(last_market.is_national_capital, true)
    assert_equal(last_market.is_island, true)
  end

  test "extant Markets updated" do
    data_point = {
      "Metro Area" => "Yaren",
      "Country" => "Republic of Nauru",
      "Income" => 100001,
      "isNationalCapital" => "no",
      "isIsland" => "no",
    }

    GameData::Inputter.send(:create_or_update_market, data_point)

    assert_equal(Market.count, 1)

    last_market = Market.last

    assert_equal(last_market.name, "Yaren")
    assert_equal(last_market.country, "Republic of Nauru")
    assert_equal(last_market.income, 100001)
    assert_equal(last_market.is_national_capital, false)
    assert_equal(last_market.is_island, false)
  end
end
