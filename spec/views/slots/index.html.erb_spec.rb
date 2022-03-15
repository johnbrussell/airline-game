require "rails_helper"

RSpec.describe "slots/index", type: :feature do
  context "viewing the page" do
    it "has a link back to the game homepage" do
      airline = Fabricate(:airline, is_user_airline: true)
      game = Game.find(airline.game_id)

      visit game_airline_slots_path(game, airline)

      expect(page).to have_link "Return to game overview"

      click_link "Return to game overview"

      expect(page).to have_content "Airline Game Home"
    end

    it "has a link back to the airline page" do
      airline = Fabricate(:airline)
      game = Game.find(airline.game_id)

      visit game_airline_slots_path(game, airline)

      expect(page).to have_link "Return to #{airline.name}"

      click_link "Return to #{airline.name}"

      expect(page).to have_content "#{airline.name}"
      expect(page).to have_content "View slot holdings"
    end

    it "shows information about all airports where the airline has slots" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, market: inu.market, iata: "FUN")
      maj = Fabricate(:airport, market: inu.market, iata: "MAJ")

      Population.create!(market_id: inu.market.id, year: 2000, population: 10000)
      Tourists.create!(market_id: inu.market.id, year: 1999, volume: 1000)

      airline = Fabricate(:airline, base_id: Airport.last.market.id, is_user_airline: true)
      game = Game.find(airline.game_id)

      family = Fabricate(:aircraft_family)
      airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)

      AirlineRoute.new(airline: airline, origin_airport: fun, destination_airport: inu, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 1).save(validate: false)
      fun_inu = AirlineRoute.last
      AirlineRoute.new(airline: airline, origin_airport: inu, destination_airport: maj, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 1).save(validate: false)
      inu_maj = AirlineRoute.last
      AirplaneRoute.new(airplane: airplane, route: fun_inu, frequencies: 3, block_time_mins: 1, flight_cost: 3).save(validate: false)
      AirplaneRoute.new(airplane: airplane, route: inu_maj, frequencies: 1, block_time_mins: 1, flight_cost: 3).save(validate: false)

      inu_gates = Gates.create!(airport: inu, current_gates: 5, game: game)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      fun_gates = Gates.create!(airport: fun, current_gates: 5, game: game)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      maj_gates = Gates.create!(airport: maj, current_gates: 5, game: game)
      Slot.create!(gates: maj_gates, lessee_id: airline.id)
      Slot.create!(gates: maj_gates, lessee_id: airline.id)
      Slot.create!(gates: maj_gates, lessee_id: airline.id)

      visit game_airline_slots_path(game, airline)

      expect(page).to have_content "#{airline.name} slot holdings"
      expect(page).to have_link "INU"
      expect(page).to have_link "FUN"
      expect(page).to have_link "MAJ"

      expect(page).to have_content "INU: 4 leased, 4 used (100%)"
      expect(page).to have_content "FUN: 4 leased, 3 used (75%)"
      expect(page).to have_content "MAJ: 3 leased, 1 used (33%)"

      click_link "INU"

      expect(page).to have_content "INU"
      expect(page).to have_content "Airport information"
    end

    it "allows users to return a slot and refresh the page" do
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, market: inu.market, iata: "FUN")
      maj = Fabricate(:airport, market: inu.market, iata: "MAJ")

      Population.create!(market_id: inu.market.id, year: 2000, population: 10000)
      Tourists.create!(market_id: inu.market.id, year: 1999, volume: 1000)

      airline = Fabricate(:airline, base_id: Airport.last.market.id, is_user_airline: true)
      game = Game.find(airline.game_id)

      family = Fabricate(:aircraft_family)
      airplane = Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)

      AirlineRoute.new(airline: airline, origin_airport: fun, destination_airport: inu, economy_price: 1, premium_economy_price: 2, business_price: 3, distance: 1).save(validate: false)
      fun_inu = AirlineRoute.last
      AirplaneRoute.new(airplane: airplane, route: fun_inu, frequencies: 3, block_time_mins: 1, flight_cost: 3).save(validate: false)

      inu_gates = Gates.create!(airport: inu, current_gates: 5, game: game)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      Slot.create!(gates: inu_gates, lessee_id: airline.id)
      fun_gates = Gates.create!(airport: fun, current_gates: 5, game: game)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)
      Slot.create!(gates: fun_gates, lessee_id: airline.id)

      visit game_airline_slots_path(game, airline)

      expect(page).to have_content "#{airline.name} slot holdings"
      expect(page).to have_link "INU"
      expect(page).to have_link "FUN"

      expect(page).to have_content "INU: 3 leased, 3 used (100%)"
      expect(page).to have_content "FUN: 4 leased, 3 used (75%)"

      expect(page).to have_button "Return a slot"

      click_button "Return a slot"

      expect(page).to have_content "FUN: 3 leased, 3 used (100%)"
      expect(page).not_to have_button "Return a slot"

      visit current_path

      expect(page).to have_content "FUN: 3 leased, 3 used (100%)"
    end
  end
end
