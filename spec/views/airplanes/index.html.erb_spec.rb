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
    aircraft_manufacturing_queue = AircraftManufacturingQueue.create!(game: game)
    Airplane.create!(
      aircraft_manufacturing_queue: aircraft_manufacturing_queue,
      operator_id: airline.id,
      construction_date: Date.yesterday,
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

    it "correctly pluralizes as the fleet grows" do
      game = Game.last
      airline = Airline.last
      Airplane.create!(
        operator_id: airline.id,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        construction_date: Date.yesterday,
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

      click_link "View airplanes"
      click_link "Return to game overview"

      expect(page).to have_content "Airline Game Home"
    end
  end
end
