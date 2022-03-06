require "rails_helper"
require "capybara/rspec"

RSpec.describe "airplanes/show", type: :feature do
  let(:game) { Fabricate(:game) }
  let(:airline) { Fabricate(:airline, game_id: game.id, is_user_airline: true) }
  let(:family) { Fabricate(:aircraft_family) }
  let(:airplane) { Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group) }

  context "viewing the page" do
    it "links back to the game homepage" do
      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_link "Return to game overview"

      click_link "Return to game overview"

      expect(page).to have_content "Airline Game Home"
    end

    it "links back to the airline fleet page" do
      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_link "Return to #{airline.name} overview"

      click_link "Return to #{airline.name} overview"

      expect(page).to have_content "#{airline.name}"
      expect(page).to have_content "Based in"
    end

    it "links back to the airline page" do
      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_link "Return to #{airline.name} fleet page"

      click_link "Return to #{airline.name} fleet page"

      expect(page).to have_content "#{airline.name} operates 1 airplane"
      expect(page).to have_content "Upcoming deliveries"
    end
  end
end