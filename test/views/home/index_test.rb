require 'test_helper'
require 'application_system_test_case'

class IndexTest < ApplicationSystemTestCase
  airline_1 = Airline.new(name: "1", cash_on_hand: 1234.56)
  airline_2 = Airline.new(name: "2", cash_on_hand: 1234.56)
  airline_3 = Airline.new(name: "3", cash_on_hand: 1234.56)
  today = Date.today
  tomorrow = today + 1
  game_1 = Game.new(start_date: today, end_date: tomorrow, current_date: today, airlines: [airline_1])

  test "the page singularizes correctly when there is only one game" do
    game_1.save!

    visit "/"

    assert_selector "h2", text: "There is 1 game in progress."
    assert_selector "li", text: "Game ID: 1 Start date: #{today} End date: #{tomorrow} Current date: #{today} There is 1 airline in the game."

    click_on "Enter"

    assert_selector "h1", text: "Game 1"
  end

  test "all games are listed on the page" do
    game_1.save!
    Game.new(start_date: tomorrow, end_date: tomorrow, current_date: tomorrow, airlines: [airline_2, airline_3]).save!

    visit "/"

    assert_selector "h2", text: "There are 2 games in progress."
    assert_selector "li", text: "Game ID: 1 Start date: #{today} End date: #{tomorrow} Current date: #{today} There is 1 airline in the game."
    assert_selector "li", text: "Game ID: 2 Start date: #{tomorrow} End date: #{tomorrow} Current date: #{tomorrow} There are 2 airlines in the game."
  end
end
