require "rails_helper"
require "capybara/rspec"

RSpec.describe "routes/index", type: :feature do
  it "has a link back to the game homepage" do
    game = Fabricate(:game)
    airline = Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "Danielle's Dirigibles")
    visit game_airline_routes_path(game, airline)

    expect(page).to have_content "Danielle's Dirigibles routes"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end
end
