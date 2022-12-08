require "rails_helper"
require "capybara/rspec"

RSpec.describe "used_airplanes/airplanes/index", type: :feature do
  context "index" do
    it "shows the number of used aircraft available" do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow)

      unsorted_aircraft = double
      family_1 = instance_double(AircraftFamily, manufacturer: "Z")
      model_1 = instance_double(AircraftModel, family: family_1, name: "200")
      family_2 = instance_double(AircraftFamily, manufacturer: "J")
      model_2 = instance_double(AircraftModel, family: family_2, name: "3000")
      used_airplane_1 = instance_double(
        Airplane,
        aircraft_model: model_1,
        construction_date: "2015-01-01".to_date,
        economy_seats: 10,
        premium_economy_seats: 9,
        business_seats: 8,
        purchase_price: 100000000,
        id: 1,
      )
      used_airplane_2 = instance_double(
        Airplane,
        aircraft_model: model_2,
        construction_date: "2010-01-01".to_date,
        economy_seats: 100,
        premium_economy_seats: 90,
        business_seats: 80,
        purchase_price: 100,
        id: 2,
      )
      used_aircraft = [used_airplane_1, used_airplane_2]
      expect(Airplane).to receive(:available_used).and_return(unsorted_aircraft)
      allow(unsorted_aircraft).to receive(:neatly_sorted).and_return(used_aircraft)

      visit game_used_airplanes_airplanes_path(game)

      expect(page).to have_content game.current_date_in_words
      expect(page).to have_content "There are 2 used airplanes available to buy or lease"
      expect(page).to have_link "Return to game overview"
      expect(page).to have_link "View new airplanes for purchase or lease"
      expect(page).to have_content "J 3000 constructed 2010-01-01. 100 economy, 90 premium economy, 80 business."
      expect(page).to have_content "Z 200 constructed 2015-01-01. 10 economy, 9 premium economy, 8 business."
      expect(page).to have_content "$100,000,000 value."
      expect(page).to have_content "$100 value."
    end
  end
end
