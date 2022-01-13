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
    Market.create!(
      name: "Boston",
      country: "United States",
      country_group: "Nauru",
      income: 100,
    )
  end

  it "has a link back to the game homepage" do
    visit game_airports_path(Game.last)

    expect(page).to have_content "Select an airport to view"
    expect(page).to have_content "There are 0 airports to choose from"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end

  it "has a dropdown of airports and redirects to the selected airport" do
    Airport.create!(iata: "BOS", market: Market.last, runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 1, longitude: 1)
    Airport.create!(iata: "INU", market: Market.last, runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 1, longitude: 1)

    visit game_airports_path(Game.last)

    expect(page).to have_content "There are 2 airports to choose from"

    select "INU - Boston, United States"

    click_on "Go"

    expect(page).to have_content "INU"
  end
end
