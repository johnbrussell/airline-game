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
      base_id: 1,
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
    end
  end
end
