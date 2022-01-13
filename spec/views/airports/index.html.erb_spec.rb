require "rails_helper"
require "capybara/rspec"

RSpec.describe "airplanes/index", type: :feature do
  before(:each) do
    game = Game.create!(
      current_date: Date.today,
      start_date: Date.yesterday,
      end_date: Date.tomorrow,
    )
    Airline.create!(
      game_id: game.id,
      name: "A Air",
      cash_on_hand: 100,
      base_id: 1,
      is_user_airline: true,
    )
  end

  it "has a link back to the game homepage" do
    visit game_airports_path(Game.last)

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end
end
