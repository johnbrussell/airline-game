require "rails_helper"
require "capybara/rspec"

RSpec.describe "airports/show", type: :feature do
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
    boston = Market.create!(
      name: "Boston",
      country: "United States",
      country_group: "United States",
      income: 100,
    )
    nauru = Market.create!(
      name: "Nauru",
      country: "Nauru",
      country_group: "Nauru",
      income: 100,
    )
    Airport.create!(iata: "BOS", market: boston, runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 1, longitude: 1)
    Airport.create!(iata: "INU", market: nauru, runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 1, longitude: 1)
  end

  it "has a link back to the game homepage" do
    visit game_airport_path(Game.last, Airport.find_by(iata: "INU"))

    expect(page).to have_content "INU"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end

  it "has a link back to airport selection" do
    visit game_airport_path(Game.last, Airport.find_by(iata: "INU"))

    expect(page).to have_content "INU"

    click_link "View a different airport"

    select "BOS - Boston, United States"

    click_on "Go"

    expect(page).to have_content "BOS"
  end
end
