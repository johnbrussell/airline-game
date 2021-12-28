require "rails_helper"
require "capybara/rspec"

RSpec.describe "new_airplanes/airplanes/index", type: :feature do
  context "index" do
    it "shows the number of new aircraft and number of used aircraft available" do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow)

      new_airplane = instance_double(Airplane)
      new_aircraft = [new_airplane]
      expect(Airplane).to receive(:all_available_new_airplanes).and_return(new_aircraft)

      visit game_new_airplanes_airplanes_path(game)

      expect(page).to have_content "There is 1 new airplane available to buy or lease"
      expect(page).to have_link "Return to game overview"
      expect(page).to have_link "View used airplanes for purchase or lease"
    end
  end
end
