require 'test_helper'
require 'application_system_test_case'

class IndexTest < ApplicationSystemTestCase
  airline = Airline.new(name: "Nauru Airlines", cash_on_hand: 1234.56, is_user_airline: true)
  today = Date.today
  tomorrow = today + 1
  game = Game.new(start_date: today, end_date: tomorrow, current_date: today, airlines: [airline])

  test "the page shows the cash on hand correctly" do
    game.save!
    game.reload

    visit game_path(game.id)

    assert_selector "h3", text: "Cash on hand: $1234.56"
  end
end
