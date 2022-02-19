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

  it "shows information about each airplane" do
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)

    visit game_add_flights_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 0 business. Currently flies 0 weekly flights"
  end

  it "allows users to add flights" do
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)
    gates_inu = Gates.create!(airport: inu, game: game, current_gates: 100)
    Slot.create!(gates: gates_inu, lessee_id: airline.id)
    Slot.create!(gates: gates_inu, lessee_id: airline.id)
    Slot.create!(gates: gates_inu, lessee_id: airline.id)
    gates_fun = Gates.create!(airport: fun, game: game, current_gates: 100)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)

    frequencies = [1, 2, 3].sample
    block_time = (aircraft_1.round_trip_block_time(Calculation::Distance.between_airports(inu, fun)) * frequencies / 60.0 / 7).round(1)
    airplane_route_count = AirplaneRoute.count

    visit game_add_flights_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 0 business. Currently flies 0 weekly flights"
    expect(page).to have_button "Set frequencies"

    fill_in :frequencies, with: frequencies

    click_on "Set frequencies"

    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 0 economy, 0 premium economy, 0 business. Currently flies #{frequencies} weekly flight"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1
  end

  it "shows an error when the flights cannot be added" do
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)
    airplane_route_count = AirplaneRoute.count

    visit game_add_flights_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expected_content = "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 0 business. Currently flies 0 weekly flights"
    expect(page).to have_content expected_content
    expect(page).to have_button "Set frequencies"

    fill_in :frequencies, with: 1

    click_on "Set frequencies"

    expect(page).to have_content expected_content
    expect(page).to have_content "Slots not leased in sufficient quantity"
    expect(AirplaneRoute.count).to eq airplane_route_count
  end
end
