require "rails_helper"
require "capybara/rspec"

RSpec.describe "routes/view_route", type: :feature do
  before(:each) do
    nauru = Fabricate(:market, name: "Nauru", country: "Nauru", country_group: "Nauru")
    funafuti = Fabricate(:market, name: "Funafuti", country: "Tuvalu", country_group: "Tuvalu")
    Fabricate(:airport, market: nauru, iata: "INU", municipality: nil, runway: 100)
    Fabricate(:airport, market: funafuti, iata: "FUN", municipality: nil, runway: 10000)
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

  it "has a link to view all airline routes" do
    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, base_id: Market.last.id)
    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "INU")})

    expect(page).to have_content "FUN - INU"

    click_link "View #{game.user_airline.name} routes"

    expect(page).to have_content "#{game.user_airline.name} routes"
  end

  it "has a link to view a different route that remembers which route it was on" do
    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "TIA", base_id: Market.last.id)
    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "INU")})

    expect(page).to have_content "FUN - INU"
    expect(page).to have_content "View a different route"

    click_link "View a different route"

    expect(page).to have_content "Select a route to view"

    click_button "Go"

    expect(page).to have_content "FUN - INU"
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
      max_business_class_revenue_per_week: 1000,
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
    expect(page).to have_content "$1,000.00 per week in business class revenue"
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
    expect(page).not_to have_content "Service quality"
    expect(page).not_to have_content "Add service on FUN - INU"
    expect(page).not_to have_button "Set frequencies"
    expect(page).to have_content "#{airline.name} cannot fly this route due to political restrictions"
    expect(page).to have_content "No airline serves FUN - INU"
    expect(page).to have_content "Service on FUN - INU"
  end

  it "shows information about airplanes able to fly the route" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{airline.name} is not currently operating flights on FUN - INU"
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
    expect(page).to have_link "#{family.manufacturer} #{model.name}"

    click_link "#{family.manufacturer} #{model.name}"

    expect(page).to have_content "Return to #{airline.name} fleet page"
  end

  it "allows users to adjust service quality" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, speed: 1000, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, business_seats: 1)
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

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "No airline serves FUN - INU"
    expect(page).to have_content "Service quality"

    fill_in :service_quality, with: 5

    click_on "Set service quality"

    expect(AirlineRoute.last.service_quality).to eq 5
  end

  it "allows users to add and remove flights" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, speed: 1000, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, business_seats: 1)
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

    expect(page).to have_content "No airline serves FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 1 business"
    expect(page).to have_button "Set frequencies"
    expect(AirlineRouteRevenue.count).to eq 0

    fill_in :frequencies, with: frequencies

    click_on "Set frequencies"

    expect(page).not_to have_content "No airline serves FUN - INU"
    expect(page).to have_content "#{airline.name} flights on FUN - INU"
    expect(page).to have_content "#{airline.name} operates #{frequencies} weekly flight#{frequencies > 1 ? "s" : ""} on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 0 economy, 0 premium economy, 1 business. Currently flies #{frequencies} weekly flight"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1
    expect(AirlineRouteRevenue.count).to eq 1

    fill_in :frequencies, with: 0

    click_on "Set frequencies"

    expect(page).to have_content "No airline serves FUN - INU"
    expect(page).to have_content "Add service on FUN - INU"
    expect(page).to have_content "#{airline.name} is not currently operating flights on FUN - INU"
    expect(page).to have_content "#{airline.name} has 1 airplane able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 1 business"
    expect(AirplaneRoute.count).to eq airplane_route_count
    expect(AirlineRouteRevenue.count).to eq 1
    expect(AirlineRouteRevenue.where("revenue > 0").count).to eq 0
  end

  it "shows user airline flight profitability information" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family, floor_space: 1000000)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, business_seats: 1)
    gates_inu = Gates.create!(airport: inu, game: game, current_gates: 100)
    Slot.create!(gates: gates_inu, lessee_id: airline.id)
    Slot.create!(gates: gates_inu, lessee_id: airline.id)
    Slot.create!(gates: gates_inu, lessee_id: airline.id)
    gates_fun = Gates.create!(airport: fun, game: game, current_gates: 100)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)

    block_time = (aircraft_1.round_trip_block_time(Calculation::Distance.between_airports(inu, fun)) / 60.0 / 7).round(1)
    airplane_route_count = AirplaneRoute.count

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "No airline serves FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 1 business"
    expect(page).to have_button "Set frequencies"
    expect(AirlineRouteRevenue.count).to eq 0

    fill_in :frequencies, with: 1

    click_on "Set frequencies"

    expect(page).to have_button "Set frequencies"

    arr = AirlineRouteRevenue.last
    airline_route = arr.airline_route
    original_revenue = arr.revenue
    desired_revenue = 10000.01
    ratio = desired_revenue / original_revenue.to_f
    apr = AirplaneRoute.last
    apr.assign_attributes(flight_cost: 10000.29)
    apr.save(validate: false)

    airplane = apr.airplane
    airplane.update!(business_seats: airplane.business_seats * ratio.ceil(), premium_economy_seats: airplane.premium_economy_seats * ratio.ceil(), economy_seats: airplane.economy_seats * ratio.ceil())
    arr.update!(revenue: 10000.01, business_pax: arr.business_pax * ratio, premium_economy_pax: arr.premium_economy_pax * ratio, economy_pax: arr.economy_pax * ratio)

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{airline.name} operates 1 weekly flight on FUN - INU. Profit: $\n-0.04\ndaily. Load factor: #{AirlineRouteRevenue.last.airline_route.load_factor.round(1)}%"
    expect(page).to have_content "Daily profit: $\n-0.04"  # Checks that airplane's profit matches route's profit when it is the only airplane flying the route
  end

  it "allows users to add flights and then updates their profitability when other airlines start service on the same route" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, speed: 1000, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, business_seats: 1)
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

    expect(page).to have_content "No airline serves FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 0 premium economy, 1 business"
    expect(page).to have_button "Set frequencies"
    expect(AirlineRouteRevenue.count).to eq 0

    fill_in :frequencies, with: frequencies

    click_on "Set frequencies"

    expect(page).to have_content "#{airline.name} operates #{frequencies} weekly flight#{frequencies > 1 ? "s" : ""} on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 0 economy, 0 premium economy, 1 business. Currently flies #{frequencies} weekly flight"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1
    expect(AirlineRouteRevenue.count).to eq 1
    revenue = AirlineRouteRevenue.last
    original_revenue = revenue.revenue
    original_pax = AirlineRouteRevenue.last.business_pax

    other_airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id)
    other_business_seats = 100000
    other_frequencies = 100
    super_model = Fabricate(:aircraft_model, family: family, takeoff_distance: 101, max_range: 13000, floor_space: Airplane::BUSINESS_SEAT_SIZE * other_business_seats)
    aircraft_2 = Fabricate(:airplane, aircraft_model: super_model, aircraft_family: family, operator_id: other_airline.id, base_country_group: airline.base.country_group, business_seats: other_business_seats)
    Slot.create!(gates: gates_inu, lessee_id: other_airline.id)
    Slot.create!(gates: gates_fun, lessee_id: other_airline.id)
    other_airline_route = AirlineRoute.create!(airline: other_airline, business_price: 1, distance: 1, origin_airport: fun, destination_airport: inu, economy_price: 1000, premium_economy_price: 10000, service_quality: 5)
    AirplaneRoute.new(route: other_airline_route, airplane: aircraft_2, frequencies: other_frequencies, flight_cost: 1, block_time_mins: 1).save(validate: false)

    click_on "Set frequencies"

    expect(page).to have_button "Set frequencies"

    click_on "Set frequencies"

    expect(page).to have_content "#{airline.name} operates #{frequencies} weekly flight#{frequencies > 1 ? "s" : ""} on FUN - INU"
    expect(page).to have_content "#{other_airline.name} operates #{other_frequencies} weekly flights with 0 economy seats, 0 premium economy seats, and #{other_business_seats * other_frequencies} business seats"

    revenue.reload
    expect(revenue.revenue).to be < original_revenue
    expect(revenue.business_pax).to be < original_pax
    expect(revenue.revenue).to be > 0
    expect(revenue.business_pax).to be > 0

    expect(page).not_to have_content "Other service between Funafuti and Nauru areas"
  end

  it "shows all service on the route and in the market" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    funafuti = Market.find_by(name: "Funafuti")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    maj = Fabricate(:airport, iata: "MAJ", market: nauru, runway: 10000)
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    other_airline = Fabricate(:airline, base_id: funafuti.id, game_id: game.id, name: "TIA")
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, speed: 1000, family: family)
    weaker_model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 10000, speed: 1000, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, business_seats: 1, premium_economy_seats: 1, economy_seats: 1)
    aircraft_2 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: other_airline.id, base_country_group: other_airline.base.country_group, business_seats: 1, premium_economy_seats: 1, economy_seats: 1)
    aircraft_3 = Fabricate(:airplane, aircraft_model: weaker_model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, business_seats: 1, premium_economy_seats: 1, economy_seats: 1)
    gates_inu = Gates.create!(airport: inu, game: game, current_gates: 100)
    Slot.create!(gates: gates_inu, lessee_id: airline.id)
    Slot.create!(gates: gates_inu, lessee_id: airline.id)
    Slot.create!(gates: gates_inu, lessee_id: airline.id)
    Slot.create!(gates: gates_inu, lessee_id: other_airline.id)
    gates_fun = Gates.create!(airport: fun, game: game, current_gates: 100)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)
    Slot.create!(gates: gates_fun, lessee_id: airline.id)
    Slot.create!(gates: gates_fun, lessee_id: other_airline.id)
    gates_maj = Gates.create!(airport: maj, game: game, current_gates: 100)
    Slot.create!(gates: gates_maj, lessee_id: airline.id)

    other_route = AirlineRoute.create!(origin_airport: fun, destination_airport: inu, airline: other_airline, economy_price: 1, premium_economy_price: 2, business_price: 4000, distance: 1008)
    AirplaneRoute.new(route: other_route, airplane: aircraft_2, frequencies: 1, block_time_mins: 1000, flight_cost: 100).save(validate: false)

    other_market_route = AirlineRoute.create!(origin_airport: fun, destination_airport: maj, airline: airline, economy_price: 2, premium_economy_price: 3, business_price: 5, distance: 1009)
    AirplaneRoute.new(route: other_market_route, airplane: aircraft_3, frequencies: 1, block_time_mins: 0, flight_cost: 100).save(validate: false)
    AirlineRouteRevenue.create!(airline_route_id: other_market_route.id, revenue: 20, exclusive_economy_revenue: 1, exclusive_business_revenue: 1, exclusive_premium_economy_revenue: 1, economy_pax: 1, business_pax: 1, premium_economy_pax: 1)

    frequencies = [1, 2, 3].sample
    block_time = (aircraft_1.round_trip_block_time(Calculation::Distance.between_airports(inu, fun)) * frequencies / 60.0 / 7).round(1)
    airplane_route_count = AirplaneRoute.count

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 1 economy, 1 premium economy, 1 business"
    expect(page).to have_button "Set frequencies"
    expect(page).to have_content "#{other_airline.name} operates 1 weekly flight with #{aircraft_2.economy_seats} economy seats, #{aircraft_2.premium_economy_seats} premium economy seats, and #{aircraft_2.business_seats} business seats. Tickets sell for $1.00 in economy, $2.00 in premium economy, and $4000.00 in business"
    expect(page).to have_content "FUN - MAJ: #{airline.name} operates 1 weekly flight with #{aircraft_1.economy_seats} economy seats, #{aircraft_1.premium_economy_seats} premium economy seats, and #{aircraft_1.business_seats} business seats. Tickets sell for $2.00 in economy, $3.00 in premium economy, and $5.00 in business"

    fill_in :frequencies, with: frequencies

    click_on "Set frequencies"

    expect(page).to have_content "#{airline.name} flights on FUN - INU"
    expect(page).to have_content "#{airline.name} operates #{frequencies} weekly flight#{frequencies > 1 ? "s" : ""} on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 1 economy, 1 premium economy, 1 business. Currently flies #{frequencies} weekly flight"
    expect(page).to have_content "#{airline.name} operates #{frequencies} weekly #{if frequencies > 1 then "flights" else "flight" end} with #{aircraft_1.economy_seats * frequencies} economy seats, #{aircraft_1.premium_economy_seats * frequencies} premium economy seats, and #{aircraft_1.business_seats * frequencies} business seats."
    expect(page).to have_content "#{other_airline.name} operates 1 weekly flight with #{aircraft_2.economy_seats} economy seats, #{aircraft_2.premium_economy_seats} premium economy seats, and #{aircraft_2.business_seats} business seats. Tickets sell for $1.00 in economy, $2.00 in premium economy, and $4000.00 in business"
    expect(page).to have_content "FUN - MAJ: #{airline.name} operates 1 weekly flight with #{aircraft_1.economy_seats} economy seats, #{aircraft_1.premium_economy_seats} premium economy seats, and #{aircraft_1.business_seats} business seats. Tickets sell for $2.00 in economy, $3.00 in premium economy, and $5.00 in business"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1

    fill_in :economy_price, with: 1.51
    fill_in :premium_economy_price, with: 1.52
    fill_in :business_price, with: 1001.38

    click_on "Set pricing"

    expect(page).to have_content "#{airline.name} flights on FUN - INU"
    expect(page).to have_content "#{airline.name} operates #{frequencies} weekly flight#{frequencies > 1 ? "s" : ""} on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 1 economy, 1 premium economy, 1 business. Currently flies #{frequencies} weekly flight"
    expect(page).to have_content "#{airline.name} operates #{frequencies} weekly #{if frequencies > 1 then "flights" else "flight" end} with #{aircraft_1.economy_seats * frequencies} economy seats, #{aircraft_1.premium_economy_seats * frequencies} premium economy seats, and #{aircraft_1.business_seats * frequencies} business seats."
    expect(page).to have_content "Tickets sell for $1.51 in economy, $1.52 in premium economy, and $1001.38 in business"
    expect(page).to have_content "#{other_airline.name} operates 1 weekly flight with #{aircraft_2.economy_seats} economy seats, #{aircraft_2.premium_economy_seats} premium economy seats, and #{aircraft_2.business_seats} business seats. Tickets sell for $1.00 in economy, $2.00 in premium economy, and $4000.00 in business"
    expect(page).to have_content "FUN - MAJ: #{airline.name} operates 1 weekly flight with #{aircraft_1.economy_seats} economy seats, #{aircraft_1.premium_economy_seats} premium economy seats, and #{aircraft_1.business_seats} business seats. Tickets sell for $2.00 in economy, $3.00 in premium economy, and $5.00 in business"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1

    fill_in :frequencies, with: 0

    click_on "Set frequencies"

    expect(page).to have_content "Add service on FUN - INU"
    expect(page).to have_content "#{airline.name} is not currently operating flights on FUN - INU"
    expect(page).to have_content "#{airline.name} has 1 airplane able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 1 economy, 1 premium economy, 1 business"
    expect(page).to have_content "#{other_airline.name} operates 1 weekly flight with #{aircraft_2.economy_seats} economy seats, #{aircraft_2.premium_economy_seats} premium economy seats, and #{aircraft_2.business_seats} business seats. Tickets sell for $1.00 in economy, $2.00 in premium economy, and $4000.00 in business"
    expect(page).to have_content "FUN - MAJ: #{airline.name} operates 1 weekly flight with #{aircraft_1.economy_seats} economy seats, #{aircraft_1.premium_economy_seats} premium economy seats, and #{aircraft_1.business_seats} business seats. Tickets sell for $2.00 in economy, $3.00 in premium economy, and $5.00 in business"
    expect(AirplaneRoute.count).to eq airplane_route_count

    expect(page).to have_link "FUN - MAJ"
    expect(page).not_to have_content "Add service on FUN - MAJ"

    click_link "FUN - MAJ"

    expect(page).to have_content "Add service on FUN - MAJ"
    expect(page).not_to have_content "Add service on FUN - INU"
    expect(page).to have_link "FUN - INU"
  end

  it "refreshing the page after adding flights works" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family, speed: 1000)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, premium_economy_seats: 1)
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

    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized 0.0 hours per day. Seating 0 economy, 1 premium economy, 0 business"
    expect(page).to have_button "Set frequencies"

    fill_in :frequencies, with: frequencies

    click_on "Set frequencies"

    expect(page).to have_content "#{airline.name} flights on FUN - INU"
    expect(page).to have_content "#{airline.name} operates #{frequencies} weekly flight#{frequencies > 1 ? "s" : ""} on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 0 economy, 1 premium economy, 0 business. Currently flies #{frequencies} weekly flight"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1

    revenue_count = AirlineRouteRevenue.count

    visit current_path

    expect(page).to have_content "#{airline.name} flights on FUN - INU"
    expect(page).to have_content "#{airline.name} operates #{frequencies} weekly flight#{frequencies > 1 ? "s" : ""} on FUN - INU"
    expect(page).to have_content "#{airline.name} has 0 airplanes able to add flights on FUN - INU"
    expect(page).to have_content "#{family.manufacturer} #{model.name} currently utilized #{block_time} hours per day. Seating 0 economy, 1 premium economy, 0 business. Currently flies #{frequencies} weekly flight"
    expect(AirplaneRoute.count).to eq airplane_route_count + 1
    expect(AirlineRouteRevenue.count).to eq revenue_count
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

  it "shows an error when the price cannot be updated" do
    game = Fabricate(:game)
    nauru = Market.find_by(name: "Nauru")
    funafuti = Market.find_by(name: "Funafuti")
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")
    airline = Fabricate(:airline, base_id: nauru.id, game_id: game.id, is_user_airline: true)
    family = Fabricate(:aircraft_family)
    model = Fabricate(:aircraft_model, max_range: 13000, takeoff_distance: 100, family: family)
    aircraft_1 = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group)
    airplane_route_count = AirplaneRoute.count

    visit game_airline_route_add_flights_path(game, -1, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_button "Set pricing"

    fill_in :business_price, with: -1
    click_on "Set pricing"

    expect(page).to have_content "Business price must be greater than 0"
    expect(AirplaneRoute.count).to eq airplane_route_count
  end
end
