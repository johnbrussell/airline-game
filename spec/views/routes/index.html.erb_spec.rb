require "rails_helper"
require "capybara/rspec"

RSpec.describe "routes/index", type: :feature do
  it "has a link back to the game homepage" do
    game = Fabricate(:game)
    airline = Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "Danielle's Dirigibles")
    visit game_airline_routes_path(game, airline)

    expect(page).to have_content "Danielle's Dirigibles routes"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end

  it "has a link to each route the airline flies" do
    game = Fabricate(:game)
    airline = Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "Danielle's Dirigibles")

    family = Fabricate(:aircraft_family)
    airplane_1 = Fabricate(:airplane, aircraft_family: family)
    airplane_2 = Fabricate(:airplane, aircraft_family: family)

    airport_1 = Fabricate(:airport, market: airline.base, iata: "AAA")
    airport_2 = Fabricate(:airport, market: airline.base, iata: "BBB")
    airport_3 = Fabricate(:airport, market: airline.base, iata: "CCC")
    airport_4 = Fabricate(:airport, market: airline.base, iata: "DDD")

    AirlineRoute.new(airline: airline, origin_airport: airport_2, destination_airport: airport_3, economy_price: 1, business_price: 2, premium_economy_price: 3, distance: 100).save(validate: false)
    route_1 = AirlineRoute.last
    AirplaneRoute.new(route: route_1, airplane: airplane_1, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
    AirlineRoute.new(airline: airline, origin_airport: airport_1, destination_airport: airport_4, economy_price: 1, business_price: 2, premium_economy_price: 3, distance: 100).save(validate: false)
    route_2 = AirlineRoute.last
    AirplaneRoute.new(route: route_2, airplane: airplane_2, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
    AirlineRoute.new(airline: airline, origin_airport: airport_1, destination_airport: airport_3, economy_price: 1, business_price: 2, premium_economy_price: 3, distance: 100).save(validate: false)

    visit game_airline_routes_path(game, airline)

    expect(page).to have_link route_1.name
    expect(page).to have_link route_2.name

    click_link route_2.name

    expect(page).to have_content route_2.name
    expect(page).not_to have_content route_1.name
    expect(page).to have_content "#{airline.name} pricing on #{route_2.name}"
  end
end