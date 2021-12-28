require "rails_helper"
require "capybara/rspec"

RSpec.describe "used_airplanes/airplanes/index", type: :feature do
  context "index" do
    it "shows the number of new aircraft and number of used aircraft available" do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow)

      used_airplane_1 = instance_double(Airplane)
      used_airplane_2 = instance_double(Airplane)
      used_aircraft = [used_airplane_1, used_airplane_2]
      expect(Airplane).to receive(:all_available_used_airplanes).and_return(used_aircraft)

      visit game_used_airplanes_airplanes_path(game)

      expect(page).to have_content "There are 2 used airplanes available to buy or lease"
    end
  end
end
