require "rails_helper"
require "capybara/rspec"

RSpec.describe "airlines/index", type: :feature do
  before(:each) do
    game = Game.create!(
      start_date: Date.today,
      end_date: Date.tomorrow,
      current_date: Date.tomorrow,
    )
    Airline.create!(
      game_id: game.id,
      name: "A Air",
      cash_on_hand: 100,
    )
    Airline.create!(
      game_id: game.id,
      name: "B Air",
      cash_on_hand: 100,
      is_user_airline: true,
    )
  end

  context "index" do
    it "shows the name of each airline" do
      game = Game.last

      visit game_airlines_path(game.id)

      expect(page).to have_content(Airline.first.name)
      expect(page).to have_content(Airline.last.name)
    end

    it "includes a link back to the game homepage" do
      game = Game.last

      visit game_airlines_path(game.id)

      expect(page).to have_content("Return to game overview")
      click_on "Return to game overview"
      expect(page).to have_content("B Air")
      expect(page).to have_content("View airlines in game")
      click_on "View airlines in game"
      expect(page).to have_content("Return to game overview")
      expect(page).to have_content(Airline.first.name)
      expect(page).to have_content(Airline.last.name)
    end
  end
end
