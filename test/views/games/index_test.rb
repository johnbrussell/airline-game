require 'test_helper'

class IndexTest < ActionDispatch::IntegrationTest
  today = Date.today
  tomorrow = today + 1
  game_1 = Game.new(start_date: today, end_date: tomorrow, current_date: today)

  test "the page singularizes correctly when there is only one game" do
    game_1.save

    get "/"
    assert_response(:success)

    assert_select "h2", "There is 1 game in progress."
    assert_select "li", "Start date: #{today} End date: #{tomorrow} Current date: #{today}"
  end

  test "all games are listed on the page" do
    game_1.save
    Game.new(start_date: tomorrow, end_date: tomorrow, current_date: tomorrow).save

    get "/"
    assert_response(:success)

    assert_select "h2", "There are 2 games in progress."
    assert_select "li", "Start date: #{today} End date: #{tomorrow} Current date: #{today}"
    assert_select "li", "Start date: #{tomorrow} End date: #{tomorrow} Current date: #{tomorrow}"
  end
end
