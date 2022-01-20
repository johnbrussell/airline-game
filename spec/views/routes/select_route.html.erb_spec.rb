require "rails_helper"
require "capybara/rspec"

RSpec.describe "routes/select_route", type: :feature do
  it "has a link back to the game homepage" do
    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id)
    visit game_select_route_path(game)

    expect(page).to have_content "Select a route to view"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end
end
