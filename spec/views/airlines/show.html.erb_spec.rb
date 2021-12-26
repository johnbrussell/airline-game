require "rails_helper"
require "capybara/rspec"

RSpec.describe "airlines/index", type: :feature do
  before(:each) do
    game = Game.create!(
      start_date: Date.today,
      end_date: Date.tomorrow,
      current_date: Date.tomorrow,
    )
    market = Market.create!(
      name: "Nauru",
      country: "Nauru",
      country_group: "A",
      income: 1000,
    )
    Airline.create!(
      game_id: game.id,
      name: "A Air",
      cash_on_hand: 100,
      base_id: market.id,
      is_user_airline: true,
    )
  end

  context "show" do
    it "shows the airline name and some useful information" do
      game = Game.last
      airline = Airline.last

      visit game_airline_path(game.id, airline.id)

      expect(page).to have_content("A Air")
      expect(page).to have_content("View airplanes")
      expect(page).to have_content("View routes")
      expect(page).to have_content("Based in Nauru, Nauru")
      expect(page).to have_content("Return to game overview")

      click_link "Return to game overview"

      expect(page).to have_content "Airline Game Home"
    end
  end
end
