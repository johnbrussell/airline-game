require 'test_helper'
require 'application_system_test_case'

class IndexTest < ApplicationSystemTestCase
  game_id = Game.last&.id || 1
  market = Market.new(name: "Nauru", country: "Nauru", country_group: "Nauru", income: 1)
  airline = Airline.new(name: "Nauru Airlines", cash_on_hand: 1234.56, is_user_airline: true, game_id: game_id)
  today = Date.today
  tomorrow = today + 1
  game = Game.new(start_date: today, end_date: tomorrow, current_date: today, airlines: [airline], id: game_id)

  test "the page shows the cash on hand and airline links correctly" do
    market.save!
    market.reload
    airline.base_id = market.id
    game.save!
    game.reload

    visit game_path(game.id)

    assert_selector "h3", text: "Cash on hand: $1235"

    assert_selector "a", text: "View airlines in game"
    click_link "View airlines in game"
    assert_selector "ul", text: game.airlines.last.name

    visit game_path(game.id)

    assert_selector "a", text: "View #{game.airlines.last.name}"
    click_link "View #{game.airlines.last.name}"
    assert_selector "h2", text: game.airlines.last.name

    visit game_path(game.id)

    assert_selector "a", text: "View new airplanes for purchase or lease"
    click_link "View new airplanes for purchase or lease"
    assert_selector "h3", text: "There are 0 new airplanes available to buy or lease"

    visit game_path(game.id)

    assert_selector "a", text: "View used airplanes for purchase or lease"
    click_link "View used airplanes for purchase or lease"
    assert_selector "h3", text: "There are 0 used airplanes available to buy or lease"

    visit game_path(game.id)
    assert_selector "a", text: "View Nauru Airlines fleet"
    click_link "View Nauru Airlines fleet"
    assert_selector "h3", text: "Nauru Airlines operates 0 airplanes"

    visit game_path(game.id)
    assert_selector "a", text: "View an airport"
    click_link "View an airport"
    assert_selector "h2", text: "Select an airport to view"
  end
end
