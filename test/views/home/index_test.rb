require 'test_helper'
require 'application_system_test_case'

class IndexTest < ApplicationSystemTestCase
  airline_1 = Airline.new(name: "Airline 1", cash_on_hand: 1234.56, is_user_airline: false)
  airline_2 = Airline.new(name: "Airline 2", cash_on_hand: 1234.56, is_user_airline: true)
  airline_3 = Airline.new(name: "Airline 3", cash_on_hand: 1234.56, is_user_airline: false)
  today = Date.today
  tomorrow = today + 1
  game_1 = Game.new(start_date: today, end_date: tomorrow, current_date: today, airlines: [airline_2, airline_1, airline_3])

  test "the page singularizes correctly when there is only one game and shows the correct airline name on its homepage" do
    game_1.save!

    visit "/"

    assert_selector "h2", text: "There is 1 game in progress."
    assert_selector "li", text: "Game ID: 1 Start date: #{today} End date: #{tomorrow} Current date: #{today} There are 3 airlines in the game."

    click_on "Enter"

    assert_selector "h1", text: "Airline 2"
  end

  test "all games are listed on the page" do
    game_1.save!
    Game.new(start_date: tomorrow, end_date: tomorrow, current_date: tomorrow, airlines: [Airline.new(name: "4", cash_on_hand: 1, is_user_airline: false)]).save!

    visit "/"

    assert_selector "h2", text: "There are 2 games in progress."
    assert_selector "li", text: "Game ID: 1 Start date: #{today} End date: #{tomorrow} Current date: #{today} There are 3 airlines in the game."
    assert_selector "li", text: "Game ID: 2 Start date: #{tomorrow} End date: #{tomorrow} Current date: #{tomorrow} There is 1 airline in the game."
  end
end
