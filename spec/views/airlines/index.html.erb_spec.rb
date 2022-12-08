require "rails_helper"
require "capybara/rspec"

RSpec.describe "airlines/index", type: :feature do
  before(:each) do
    game = Game.create!(
      start_date: Date.today,
      end_date: Date.tomorrow,
      current_date: Date.tomorrow,
    )
    market = Fabricate(
      :market, 
      name: "AB",
      country: "AB",
      country_group: "AB",
      income: 1000,
    )
    Airline.create!(
      game_id: game.id,
      name: "A Air",
      cash_on_hand: 100,
      base_id: market.id,
    )
    Airline.create!(
      game_id: game.id,
      name: "B Air",
      cash_on_hand: 100,
      is_user_airline: true,
      base_id: market.id,
    )
  end

  context "index" do
    it "shows the name of each airline" do
      game = Game.last
      other_game = Game.create!(
        start_date: Date.tomorrow,
        current_date: Date.tomorrow + 1.day,
        end_date: Date.tomorrow + 2.days,
      )
      Airline.create!(
        game_id: other_game.id,
        name: "C Air",
        cash_on_hand: 0,
        base_id: 1,
      )

      visit game_airlines_path(game.id)

      expect(page).to have_content game.current_date_in_words

      expect(page).to have_content("A Air")
      expect(page).to have_content("B Air")
      expect(page).not_to have_content("C Air")

      click_on "A Air"
      expect(page).to have_content("A Air")
      expect(page).not_to have_content("B Air")
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
