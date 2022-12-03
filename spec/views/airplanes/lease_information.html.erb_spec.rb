require "rails_helper"
require "capybara/rspec"

RSpec.describe "airplanes/lease_information", type: :feature do
  before(:each) do
    game = Game.create!(
      start_date: Date.today,
      end_date: Date.today + 1.day,
      current_date: Date.today + 1.day,
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
      cash_on_hand: 100000,
      base_id: market.id,
      is_user_airline: true,
    )
    family = AircraftFamily.create!(
      name: "737",
      manufacturer: "Boeing",
      country_group: "United States",
    )
    AircraftManufacturingQueue.create!(game: game, production_rate: 0.1, aircraft_family_id: family.id)
    AircraftModel.create!(
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
  end

  context "lease_information" do
    context "new airplane" do
      before(:each) do
        Airplane.create!(
          aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
          base_country_group: "United States",
          operator_id: nil,
          construction_date: Date.tomorrow + 1.day,
          end_of_useful_life: Date.tomorrow + 1.year,
          aircraft_model: AircraftModel.last,
        )
      end

      it "shows information about the airplane model and the cost to lease" do
        game = Game.last
        airplane = Airplane.last

        visit game_airplane_lease_path(game.id, airplane.id)

        expect(page).to have_content("Lease a new 737-300")
        expect(page).to have_content("Constructed in United States")
        expect(page).to have_content(airplane.construction_date)
        expect(page).to have_content("A Air has $100000.00 on hand")
        expect(page).to have_content("1 year lease: ")
        expect(page).to have_content("5 year lease: ")
        expect(page).to have_content("10 year lease: ")
        expect(page).to have_content("Lease rate is up to ")
        expect(page).to have_content(" with discounts for longer leases")
        expect(page).to have_content("737-300s have 100000 square inches of floor space")
        expect(page).not_to have_content("This airplane currently has 0 business seats, 0 premium economy seats, and 0 economy seats.")
      end

      it "redirects to the airline fleet page after leasing" do
        game = Game.last
        airplane = Airplane.last

        visit game_airplane_lease_path(game.id, airplane.id)

        fill_in :airplane_days, with: 1
        fill_in :airplane_business_seats, with: 1
        fill_in :airplane_premium_economy_seats, with: 1
        fill_in :airplane_economy_seats, with: 1
        click_button "Lease"

        expect(page).to have_content "A Air fleet"
        airplane.reload

        expect(airplane.business_seats).to eq 1
        expect(airplane.premium_economy_seats).to eq 1
        expect(airplane.economy_seats).to eq 1
      end

      it "does not show the airplane on the new airplane page again after leasing" do
        game = Game.last
        airplane = Airplane.last

        visit game_new_airplanes_airplanes_path(game)

        expect(page).to have_content "There is 1 new airplane available to buy or lease"
        expect(page).to have_content "Boeing 737-300 to be delivered #{airplane.construction_date}"

        click_button "View lease details"

        fill_in :airplane_days, with: 1
        fill_in :airplane_business_seats, with: 1
        fill_in :airplane_premium_economy_seats, with: 1
        fill_in :airplane_economy_seats, with: 1
        click_button "Lease"

        expect(page).to have_content "A Air fleet"

        visit game_new_airplanes_airplanes_path(game)

        expect(page).to have_content "There are 0 new airplanes available to buy or lease"
        expect(page).not_to have_content "Boeing 737-300 to be delivered #{airplane.construction_date}"
      end

      it "does not redirect to the airline fleet page when a validation error occurs" do
        game = Game.last
        airplane = Airplane.last

        visit game_airplane_lease_path(game.id, airplane.id)

        fill_in :airplane_days, with: 1
        fill_in :airplane_business_seats, with: 100
        fill_in :airplane_premium_economy_seats, with: 100
        fill_in :airplane_economy_seats, with: 100
        click_button "Lease"

        expect(page).to have_content "Lease a new 737-300"
        expect(page).to have_content "Constructed in United States"
        expect(page).to have_content "Seats require more total floor space than available on airplane"
        expect(page).not_to have_content "A Air fleet"
      end

      it "has a functional cancel button" do
        game = Game.last
        airplane = Airplane.last

        visit game_new_airplanes_airplanes_path(game)

        expect(page).to have_content "There is 1 new airplane available to buy or lease"
        expect(page).to have_content "Boeing 737-300 to be delivered #{airplane.construction_date}"

        click_button "View lease details"

        click_button "Cancel"

        expect(page).to have_content "There is 1 new airplane available to buy or lease"
        expect(page).to have_content "Boeing 737-300 to be delivered #{airplane.construction_date}"
      end
    end

    context "used airplane" do
      before(:each) do
        Airplane.create!(
          aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
          base_country_group: "United States",
          operator_id: nil,
          construction_date: Date.today,
          end_of_useful_life: Date.tomorrow + 1.year,
          aircraft_model: AircraftModel.last,
        )
      end

      it "shows information about the airplane model and the cost to lease" do
        game = Game.last
        airplane = Airplane.last

        visit game_airplane_lease_path(game.id, airplane.id)

        expect(page).to have_content("Lease a used 737-300")
        expect(page).to have_content("Based in United States")
        expect(page).to have_content("#{airplane.construction_date} (1 day old)")
        expect(page).to have_content("A Air has $100000.00 on hand")
        expect(page).to have_content("1 year lease: ")
        expect(page).to have_content("5 year lease: ")
        expect(page).to have_content("10 year lease: ")
        expect(page).to have_content("Lease rate is up to ")
        expect(page).to have_content(" with discounts for longer leases")
        expect(page).to have_content("This airplane currently has 0 business seats, 0 premium economy seats, and 0 economy seats.")
        expect(page).not_to have_content("737-300s have 100000 square inches of floor space")
      end

      it "redirects to the airline fleet page after leasing" do
        game = Game.last
        airplane = Airplane.last

        visit game_airplane_lease_path(game.id, airplane.id)

        fill_in :airplane_days, with: 1
        click_button "Lease"

        expect(page).to have_content "A Air fleet"
        expect(page).to have_content "Boeing 737-300 constructed #{airplane.construction_date}"
        airplane.reload

        expect(airplane.operator_id).to eq Airline.where(name: "A Air").last.id
      end

      it "redirects to the airline fleet page after leasing a pre-owned aircraft" do
        game = Game.last
        previous_owner = Fabricate(:airline, base_id: Airline.last.base_id, cash_on_hand: 100, name: "Nauru Airlines")
        airplane = Airplane.last
        airplane.update!(owner_id: previous_owner.id)

        visit game_airplane_lease_path(game.id, airplane.id)

        fill_in :airplane_days, with: 1
        click_button "Lease"

        expect(page).to have_content "A Air fleet"
        expect(page).to have_content "Boeing 737-300 constructed #{airplane.construction_date}"
        airplane.reload
        previous_owner.reload

        expect(airplane.owner_id).to be nil
        expect(airplane.operator_id).to eq Airline.where(name: "A Air").last.id
        expect(previous_owner.cash_on_hand).to be > 100
      end

      it "does not show the airplane on the used airplane page again after leasing" do
        game = Game.last
        airplane = Airplane.last

        visit game_used_airplanes_airplanes_path(game)

        expect(page).to have_content "There is 1 used airplane available to buy or lease"
        expect(page).to have_content "Boeing 737-300 constructed #{airplane.construction_date}"

        click_button "View lease details"

        fill_in :airplane_days, with: 1
        click_button "Lease"

        expect(page).to have_content "A Air fleet"
        expect(page).to have_content "Boeing 737-300 constructed #{airplane.construction_date}"

        visit game_used_airplanes_airplanes_path(game)

        expect(page).to have_content "There are 0 used airplanes available to buy or lease"
        expect(page).not_to have_content "Boeing 737-300 constructed #{airplane.construction_date}"
      end

      it "does not redirect to the airline fleet page when a validation error occurs" do
        game = Game.last
        airplane = Airplane.last
        Airline.last.update!(cash_on_hand: 1)
        previous_owner = Fabricate(:airline, base_id: Airline.last.base_id, cash_on_hand: 100)
        airplane.update!(owner_id: previous_owner.id)

        visit game_airplane_lease_path(game.id, airplane.id)

        fill_in :airplane_days, with: 1
        click_button "Lease"

        expect(page).to have_content "Lease a used 737-300"
        expect(page).to have_content "Based in United States"
        expect(page).to have_content "Buyer does not have enough cash on hand to lease"
        expect(page).not_to have_content "A Air fleet"

        airplane.reload
        previous_owner.reload

        expect(airplane.owner_id).to eq previous_owner.id
        expect(previous_owner.cash_on_hand).to eq 100
      end

      it "has a functional cancel button" do
        game = Game.last
        airplane = Airplane.last

        visit game_used_airplanes_airplanes_path(game)

        expect(page).to have_content "There is 1 used airplane available to buy or lease"
        expect(page).to have_content "Boeing 737-300 constructed #{airplane.construction_date}"

        click_button "View lease details"

        click_button "Cancel"

        expect(page).to have_content "There is 1 used airplane available to buy or lease"
        expect(page).to have_content "Boeing 737-300 constructed #{airplane.construction_date}"
      end
    end
  end
end
