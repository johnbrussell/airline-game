require "rails_helper"
require "capybara/rspec"

RSpec.describe "game/airplanes/index", type: :feature do
  context "index" do
    it "shows the number of new aircraft and number of used aircraft available" do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow)

      new_airplane = instance_double(Airplane)
      used_airplane_1 = instance_double(Airplane)
      used_airplane_2 = instance_double(Airplane)
      new_aircraft = [new_airplane]
      used_aircraft = [used_airplane_1, used_airplane_2]
      expect(Airplane).to receive(:all_available_new_airplanes).and_return(new_aircraft)
      expect(Airplane).to receive(:all_available_used_airplanes).and_return(used_aircraft)

      visit game_game_airplanes_path(game)

      expect(page).to have_content "There is 1 new airplane available to buy or lease"
      expect(page).to have_content "There are 2 used airplanes available to buy or lease"
    end
  end
end
