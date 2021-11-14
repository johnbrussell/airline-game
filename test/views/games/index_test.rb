require 'test_helper'

class IndexTest < ActionDispatch::IntegrationTest
  airline_1 = Airline.new(name: "1")
  airline_2 = Airline.new(name: "2")
  airline_3 = Airline.new(name: "3")
  today = Date.today
  tomorrow = today + 1
  game_1 = Game.new(start_date: today, end_date: tomorrow, current_date: today, airlines: [airline_1])

  test "the page singularizes correctly when there is only one game" do
    game_1.save

    get "/"
    assert_response(:success)

    assert_select "h2", "There is 1 game in progress."
    assert_select "li", "Game ID: 1 Start date: #{today} End date: #{tomorrow} Current date: #{today}\n      There is 1 airline in the game."
  end

  test "all games are listed on the page" do
    game_1.save
    Game.new(start_date: tomorrow, end_date: tomorrow, current_date: tomorrow, airlines: [airline_2, airline_3]).save

    get "/"
    assert_response(:success)

    assert_select "h2", "There are 2 games in progress."
    assert_select "li", "Game ID: 1 Start date: #{today} End date: #{tomorrow} Current date: #{today}\n      There is 1 airline in the game."
    assert_select "li", "Game ID: 2 Start date: #{tomorrow} End date: #{tomorrow} Current date: #{tomorrow}\n      There are 2 airlines in the game."
  end
end
