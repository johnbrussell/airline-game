require "rails_helper"
require "capybara/rspec"

RSpec.describe "routes/add_flights", type: :feature do
  let(:nauru) { Fabricate(:market, name: "Nauru", country: "Nauru", country_group: "Nauru") }
  let(:funafuti) { Fabricate(:market, name: "Funafuti", country: "Tuvalu", country_group: "Tuvalu") }
  let(:inu) { Fabricate(:airport, market: nauru, iata: "INU", municipality: nil) }
  let(:fun) { Fabricate(:airport, market: funafuti, iata: "FUN", municipality: nil) }
  let(:game) { Fabricate(:game) }

  it "shows information about the route" do
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)

    visit game_add_flights_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "Adjust service on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to serve FUN - INU"
  end

  it "correctly singularizes the number of airplanes when necessary" do
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family)
    aircraft = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)

    visit game_add_flights_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "Adjust service on FUN - INU"
    expect(page).to have_content "#{airline.name} has 1 airplane able to serve FUN - INU"
  end
end
