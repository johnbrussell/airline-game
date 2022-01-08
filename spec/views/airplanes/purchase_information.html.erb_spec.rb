require "rails_helper"
require "capybara/rspec"

RSpec.describe "airplanes/purchase_information", type: :feature do
  before(:each) do
    game = Game.create!(
      start_date: Date.today,
      end_date: Date.tomorrow,
      current_date: Date.tomorrow,
    )
    market = Market.create!(
      name: "AB",
      country: "AB",
      country_group: "AB",
      income: 1000,
    )
    airline = Airline.create!(
      game_id: game.id,
      name: "A Air",
      cash_on_hand: 100000000,
      base_id: market.id,
      is_user_airline: true,
    )
    family = AircraftFamily.create!(
      name: "737",
      manufacturer: "Boeing",
    )
    queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0.1, aircraft_family_id: family.id)
    model = AircraftModel.create!(
      name: "737-300",
      production_start_year: 1980,
      floor_space: 100000,
      max_range: 100,
      speed: 500,
      num_pilots: 2,
      num_flight_attendants: 3,
      price: 100000000,
      takeoff_distance: 6000,
      useful_life: 30,
      fuel_burn: 100,
      family: family,
    )
    Airplane.create!(
      aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
      operator_id: nil,
      construction_date: Date.tomorrow + 1.day,
      end_of_useful_life: Date.tomorrow + 1.year,
      aircraft_model: AircraftModel.last,
    )
  end

  context "purchase_information" do
    it "shows information about the airplane model and the cost to purchase" do
      game = Game.last
      airplane = Airplane.last

      visit game_airplane_purchase_path(game.id, airplane.id)

      expect(page).to have_content("Order a new 737-300")
      expect(page).to have_content(airplane.construction_date)
      expect(page).to have_content("Due now: $50000000.00")
      expect(page).to have_content("Due on #{airplane.construction_date}: $50000000.00")
      expect(page).to have_content("Total price: $100000000.00")
      expect(page).to have_content("A Air has $100000000.00 available")
      expect(page).to have_content("737-300s have 100000 square inches of floor space")
    end

    it "redirects to the airline fleet page after ordering" do
      game = Game.last
      airplane = Airplane.last

      visit game_airplane_purchase_path(game.id, airplane.id)

      fill_in :airplane_business_seats, with: 1
      fill_in :airplane_premium_economy_seats, with: 1
      fill_in :airplane_economy_seats, with: 1
      click_button "Purchase"

      expect(page).to have_content "A Air fleet"
      airplane.reload

      expect(airplane.business_seats).to eq 1
      expect(airplane.premium_economy_seats).to eq 1
      expect(airplane.economy_seats).to eq 1
    end

    it "has a functional cancel button" do
      game = Game.last
      airplane = Airplane.last

      visit game_new_airplanes_airplanes_path(game)

      expect(page).to have_content "There is 1 new airplane available to buy or lease"
      expect(page).to have_content "Boeing 737-300 constructed #{airplane.construction_date}"

      click_button "Buy"

      click_button "Cancel"

      expect(page).to have_content "There is 1 new airplane available to buy or lease"
      expect(page).to have_content "Boeing 737-300 constructed #{airplane.construction_date}"
    end

    it "does not show the airplane on the new airplane page again after buying" do
      game = Game.last
      airplane = Airplane.last

      visit game_new_airplanes_airplanes_path(game)

      expect(page).to have_content "There is 1 new airplane available to buy or lease"
      expect(page).to have_content "Boeing 737-300 constructed #{airplane.construction_date}"

      click_button "Buy"

      fill_in :airplane_business_seats, with: 1
      fill_in :airplane_premium_economy_seats, with: 1
      fill_in :airplane_economy_seats, with: 1
      click_button "Purchase"

      expect(page).to have_content "A Air fleet"

      visit game_new_airplanes_airplanes_path(game)

      expect(page).to have_content "There are 0 new airplanes available to buy or lease"
      expect(page).not_to have_content "Boeing 737-300 constructed #{airplane.construction_date}"
    end

    it "does not redirect to the airline fleet page when a validation error occurs" do
      game = Game.last
      airplane = Airplane.last

      visit game_airplane_purchase_path(game.id, airplane.id)

      fill_in :airplane_business_seats, with: 100
      fill_in :airplane_premium_economy_seats, with: 100
      fill_in :airplane_economy_seats, with: 100
      click_button "Purchase"

      expect(page).to have_content "Seats require more total floor space than available on airplane"
      expect(page).not_to have_content "A Air fleet"
    end
  end
end