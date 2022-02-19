require "rails_helper"
require "capybara/rspec"

RSpec.describe "routes/view_route", type: :feature do
  before(:each) do
    nauru = Fabricate(:market, name: "Nauru", country: "Nauru", country_group: "Nauru")
    funafuti = Fabricate(:market, name: "Funafuti", country: "Tuvalu", country_group: "Tuvalu")
    Fabricate(:airport, market: nauru, iata: "INU", municipality: nil)
    Fabricate(:airport, market: funafuti, iata: "FUN", municipality: nil)
    Population.create!(market_id: funafuti.id, year: 2020, population: 10000)
    Population.create!(market_id: nauru.id, year: 2000, population: 14000)
    Tourists.create!(market_id: nauru.id, year: 1999, volume: 100)
    Tourists.create!(market_id: funafuti.id, year: 2020, volume: 2700)
  end

  it "has a link back to the game homepage" do
    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, base_id: Market.last.id)
    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "INU")})

    expect(page).to have_content "FUN - INU"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end

  it "has a link to view a different route" do
    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "TIA", base_id: Market.last.id)
    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "INU")})

    expect(page).to have_content "View a different route"

    click_link "View a different route"

    expect(page).to have_content "Select a route to view"
  end

  it "displays the route in alphabetical order" do
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")

    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "TIA", base_id: inu.market.id)

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "FUN - INU"

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: fun.id, destination_id: inu.id })

    expect(page).to have_content "FUN - INU"
  end

  it "displays information about the route" do
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")

    game = Fabricate(:game)
    airline = Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "TIA", base_id: inu.market.id)

    revenue_calculator = instance_double(
      Calculation::MaximumRevenuePotential,
      max_business_class_revenue_per_week: 100,
      max_premium_economy_class_revenue_per_week: 200,
      max_economy_class_revenue_per_week: 400,
    )
    allow(Calculation::Distance).to receive(:between_airports).and_return(1000)
    allow(Calculation::MaximumRevenuePotential).to receive(:new).and_return(revenue_calculator)

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "1000 miles"
    expect(page).to have_content "At current demand levels, this route can support up to:"
    expect(page).to have_content "$400.00 per week in economy class revenue"
    expect(page).to have_content "$200.00 per week in premium economy class revenue"
    expect(page).to have_content "$100.00 per week in business class revenue"
    expect(page).not_to have_content "#{airline.name} cannot fly this route due to political restrictions"
  end

  it "displays the number of available slots the airline has at the origin and destination" do
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")

    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "TIA", base_id: inu.market.id)

    expect(Slot).to receive(:num_leased).twice.with(game.user_airline, inu).and_return(5)
    expect(Slot).to receive(:num_leased).twice.with(game.user_airline, fun).and_return(6)
    expect(Slot).to receive(:num_used).twice.with(game.user_airline, inu).and_return(4)
    expect(Slot).to receive(:num_used).twice.with(game.user_airline, fun).and_return(2)

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "TIA has 1 available slot at INU"
    expect(page).to have_content "TIA has 4 available slots at FUN"
  end

  it "links to the origin and destination" do
    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, base_id: Market.last.id)
    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "INU")})

    expect(page).to have_content "FUN - INU"

    expect(page).to have_content "View FUN"
    click_link "View FUN"

    expect(page).to have_content "Funafuti (FUN)"

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "INU")})

    expect(page).to have_content "View INU"
    click_link "View INU"

    expect(page).to have_content "Nauru (INU)"
  end

  it "has no button to add or remove service if the airline cannot fly the route" do
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    RivalCountryGroup.create!(country_one: inu.market.country_group, country_two: fun.market.country_group)

    game = Fabricate(:game)
    airline = Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "TIA", base_id: inu.market.id)

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).not_to have_content "#{airline.name} flights on FUN - INU"
    expect(page).not_to have_content "Add service on FUN - INU"
    expect(page).not_to have_button "Set frequencies"
    expect(page).to have_content "#{airline.name} cannot fly this route due to political restrictions"
  end

  it "shows information about airplanes able to fly the route" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{airline.name} has 0 airplanes currently operating flights on FUN - INU"
  end

  it "correctly singularizes the number of airplanes when necessary" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family)
    aircraft = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{airline.name} has 1 airplane able to add flights on FUN - INU"
  end

  it "shows information about each airplane" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 0 business"
  end

  it "allows users to add and remove flights" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
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

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 0 business"
    expect(page).to have_button "Set frequencies"

    fill_in :frequencies, with: frequencies

    click_on "Set frequencies"

    expect(page).to have_content "#{airline.name} flights on FUN - INU"
    expect(page).to have_content "#{airline.name} has 1 airplane currently operating flights on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 0 economy, 0 premium economy, 0 business. Currently flies #{frequencies} weekly flight"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1

    fill_in :frequencies, with: 0

    click_on "Set frequencies"

    expect(page).to have_content "Add service on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes currently operating flights on FUN - INU"
    expect(page).to have_content "#{airline.name} has 1 airplane able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 0 business"
    expect(AirplaneRoute.count).to eq airplane_route_count
  end

  it "refreshing the page after adding flights works" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
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

    visit game_airline_route_add_flights_path(game, 0, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 0 business"
    expect(page).to have_button "Set frequencies"

    fill_in :frequencies, with: frequencies

    click_on "Set frequencies"

    expect(page).to have_content "#{airline.name} flights on FUN - INU"
    expect(page).to have_content "#{airline.name} has 1 airplane currently operating flights on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 0 economy, 0 premium economy, 0 business. Currently flies #{frequencies} weekly flight"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1

    visit current_path

    expect(page).to have_content "#{airline.name} flights on FUN - INU"
    expect(page).to have_content "#{airline.name} has 1 airplane currently operating flights on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 0 economy, 0 premium economy, 0 business. Currently flies #{frequencies} weekly flight"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1
  end

  it "shows an error when the flights cannot be added" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)
    airplane_route_count = AirplaneRoute.count

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expected_content = "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 0 business"
    expect(page).to have_content expected_content
    expect(page).to have_button "Set frequencies"

    fill_in :frequencies, with: 1

    click_on "Set frequencies"

    expect(page).to have_content expected_content
    expect(page).to have_content "Slots not leased in sufficient quantity"
    expect(AirplaneRoute.count).to eq airplane_route_count
  end
end
