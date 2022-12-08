require "rails_helper"

RSpec.describe "airplanes/change_configuration", type: :feature do
  context "changing the configuration" do
    let(:game) { Fabricate(:game) }
    let(:airline) { Fabricate(:airline, game_id: game.id, cash_on_hand: 100000000, name: "American Airlines", is_user_airline: true) }
    let(:family) { Fabricate(:aircraft_family) }
    let(:airplane) { Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group) }

    it "shows information about the airplane" do
      visit game_airline_airplane_change_configuration_path(game, airline, airplane)

      expect(page).to have_content game.current_date_in_words
      expect(page).to have_content "#{airplane.family.manufacturer} #{airplane.aircraft_model.name}"
      expect(page).to have_content "Maximum seats in all economy configuration: #{airplane.aircraft_model.floor_space / Airplane::ECONOMY_SEAT_SIZE}"
      expect(page).to have_content "Cost per economy seat"
      expect(page).to have_content "Cost per premium economy seat"
      expect(page).to have_content "Cost per business seat"
      expect(page).to have_content "This airplane will not earn any operating profits on the days it is being reconfigured"
      expect(page).to have_content "American Airlines has $100,000,000 on hand"
    end

    it "has a cancel button that returns to the view page" do
      visit game_airline_airplane_change_configuration_path(game, airline, airplane)

      expect(page).to have_content "#{airplane.family.manufacturer} #{airplane.aircraft_model.name}"
      expect(page).not_to have_content "Takeoff length"

      click_button "Cancel"

      expect(page).to have_content "#{airplane.family.manufacturer} #{airplane.aircraft_model.name}"
      expect(page).to have_content "Takeoff length"
    end

    it "shows an error on the change configuation page if the change is not successful" do
      visit game_airline_airplane_change_configuration_path(game, airline, airplane)

      fill_in :airplane_economy_seats, with: 1000000000
      click_button "Change"

      expect(page).to have_content "Seats require more total floor space than available on airplane"
      expect(page).not_to have_content "Takeoff length"
    end

    it "can be refreshed after an unsuccessful change on the change configuation page" do
      visit game_airline_airplane_change_configuration_path(game, airline, airplane)

      fill_in :airplane_economy_seats, with: 1000000000
      click_button "Change"

      expect(page).to have_content "Seats require more total floor space than available on airplane"

      visit current_path

      expect(page).to have_content "Change aircraft configuration"
    end

    it "returns to the airplane view page if the change is successful" do
      visit game_airline_airplane_change_configuration_path(game, airline, airplane)

      fill_in :airplane_business_seats, with: 4
      fill_in :airplane_premium_economy_seats, with: 2
      fill_in :airplane_economy_seats, with: 1
      click_button "Change"

      expect(page).to have_content "4 business seats"
      expect(page).to have_content "2 premium economy seats"
      expect(page).to have_content "1 economy seat"
    end
  end
end
