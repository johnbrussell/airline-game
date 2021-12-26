require 'test_helper'
require 'application_system_test_case'

class IndexTest < ApplicationSystemTestCase
  market = Market.new(name: "Nauru", country: "Nauru", country_group: "Nauru", income: 1)
  airline = Airline.new(name: "Nauru Airlines", cash_on_hand: 1234.56, is_user_airline: true)
  today = Date.today
  tomorrow = today + 1
  game = Game.new(start_date: today, end_date: tomorrow, current_date: today, airlines: [airline])

  test "the page shows the cash on hand and airline links correctly" do
    market.save!
    market.reload
    airline.base_id = market.id
    game.save!
    game.reload

    visit game_path(game.id)

    assert_selector "h3", text: "Cash on hand: $1234.56"

    assert_selector "a", text: "View airlines in game"
    click_link "View airlines in game"
    assert_selector "ul", text: game.airlines.last.name

    visit game_path(game.id)

    assert_selector "a", text: "View #{game.airlines.last.name}"
    click_link "View #{game.airlines.last.name}"
    assert_selector "h2", text: game.airlines.last.name
  end
end
