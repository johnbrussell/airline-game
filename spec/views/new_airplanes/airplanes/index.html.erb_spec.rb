require "rails_helper"
require "capybara/rspec"

RSpec.describe "new_airplanes/airplanes/index", type: :feature do
  context "index" do
    it "shows the number of new aircraft available" do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow)

      unsorted_aircraft = double
      family = instance_double(AircraftFamily, manufacturer: "Z")
      model = instance_double(AircraftModel, family: family, name: "200")
      new_airplane = instance_double(Airplane, aircraft_model: model, construction_date: "1915-01-01".to_date, economy_seats: 10, premium_economy_seats: 9, business_seats: 8)
      new_aircraft = [new_airplane]
      expect(Airplane).to receive(:available_new).and_return(unsorted_aircraft)
      allow(unsorted_aircraft).to receive(:neatly_sorted).and_return(new_aircraft)

      visit game_new_airplanes_airplanes_path(game)

      expect(page).to have_content "There is 1 new airplane available to buy or lease"
      expect(page).to have_link "Return to game overview"
      expect(page).to have_link "View used airplanes for purchase or lease"
      expect(page).to have_content "Z 200 constructed 1915-01-01. 10 economy, 9 premium economy, 8 business."
    end
  end
end
