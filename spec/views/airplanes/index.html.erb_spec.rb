require "rails_helper"
require "capybara/rspec"

RSpec.describe "airplanes/index", type: :feature do
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
      cash_on_hand: 100,
      base_id: market.id,
      is_user_airline: true,
    )
    family = AircraftFamily.create!(
      name: "737",
      manufacturer: "Boeing",
    )
    aircraft_manufacturing_queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0.1, aircraft_family_id: family.id)
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
      aircraft_manufacturing_queue: aircraft_manufacturing_queue,
      operator_id: airline.id,
      construction_date: "2020-01-01".to_date,
      end_of_useful_life: Date.tomorrow,
      aircraft_model: model,
    )
  end

  context "index" do
    it "shows the name of the airline and a count of the fleet" do
      game = Game.last
      airline = Airline.last

      visit game_airline_airplanes_path(game.id, airline.id)

      expect(page).to have_content("A Air fleet")
      expect(page).to have_content("A Air operates 1 airplane")
    end

    it "shows details about the fleet" do
      game = Game.last
      airline = Airline.last
      Airplane.create!(
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        operator_id: airline.id,
        construction_date: "2019-01-01".to_date,
        end_of_useful_life: Date.tomorrow,
        aircraft_model: AircraftModel.last,
        economy_seats: 100,
        premium_economy_seats: 10,
        business_seats: 8,
      )

      visit game_airline_airplanes_path(game.id, airline.id)

      expect(page).to have_content("A Air operates 2 airplanes")
      expect(page).to have_content("Boeing 737-300 constructed 2020-01-01. 0 economy, 0 premium economy, 0 business.")
      expect(page).to have_content("Boeing 737-300 constructed 2019-01-01. 100 economy, 10 premium economy, 8 business.")
    end

    it "correctly pluralizes as the fleet grows" do
      game = Game.last
      airline = Airline.last
      Airplane.create!(
        operator_id: airline.id,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        construction_date: Date.yesterday,
        end_of_useful_life: Date.tomorrow,
        aircraft_model: AircraftModel.last,
      )

      visit game_airline_airplanes_path(game.id, airline.id)

      expect(page).to have_content "A Air operates 2 airplanes"
    end

    it "excludes unconstructed airplanes" do
      game = Game.last
      airline = Airline.last
      Airplane.create!(
        operator_id: airline.id,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + 1.year,
        aircraft_model: AircraftModel.last,
      )

      visit game_airline_airplanes_path(game.id, airline.id)

      expect(page).to have_content "A Air operates 1 airplane"
    end

    it "has links back to the airline page and game overview page" do
      game = Game.last
      airline = Airline.last

      visit game_airline_airplanes_path(game.id, airline.id)

      click_link "Return to airline page"

      expect(page).to have_content "A Air"
      expect(page).to have_content "Based in AB, AB"

      click_link "View fleet"
      click_link "Return to game overview"

      expect(page).to have_content "Airline Game Home"
    end
  end
end
