require "rails_helper"
require "capybara/rspec"

RSpec.describe "routes/index", type: :feature do
  it "has a link back to the game homepage" do
    game = Fabricate(:game)
    airline = Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "Danielle's Dirigibles")
    visit game_airline_routes_path(game, airline)

    expect(page).to have_content game.current_date_in_words
    expect(page).to have_content "Danielle's Dirigibles routes"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end

  it "has a link to the airline page" do
    game = Fabricate(:game)
    airline = Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "Danielle's Dirigibles")
    visit game_airline_routes_path(game, airline)

    expect(page).to have_content "View Danielle's Dirigibles"

    click_link "View Danielle's Dirigibles"

    expect(page).to have_content "Danielle's Dirigibles"
    expect(page).to have_content "Based in #{airline.base.name}"
  end

  it "has a link to each route the airline flies" do
    game = Fabricate(:game)
    airline = Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "Danielle's Dirigibles")

    other_market = Fabricate(:market, name: "Other")
    Population.create!(market_id: other_market.id, year: 2000, population: 1)
    Tourists.create!(market_id: other_market.id, year: 2001, volume: 10000000)

    family = Fabricate(:aircraft_family)
    airplane_1 = Fabricate(:airplane, aircraft_family: family)
    airplane_2 = Fabricate(:airplane, aircraft_family: family)

    airport_1 = Fabricate(:airport, market: airline.base, iata: "AAA")
    airport_2 = Fabricate(:airport, market: airline.base, iata: "BBB")
    airport_3 = Fabricate(:airport, market: other_market, iata: "CCC")
    airport_4 = Fabricate(:airport, market: airline.base, iata: "DDD")

    AirlineRoute.new(airline: airline, origin_airport: airport_2, destination_airport: airport_3, economy_price: 1, business_price: 2, premium_economy_price: 3).save(validate: false)
    route_1 = AirlineRoute.last
    AirlineRouteRevenue.new(airline_route_id: route_1.id, revenue: 100, exclusive_economy_revenue: 1, exclusive_premium_economy_revenue: 2, exclusive_business_revenue: 3, business_pax: 1, economy_pax: 2, premium_economy_pax: 1).save(validate: false)
    AirplaneRoute.new(route: route_1, airplane: airplane_1, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
    AirlineRoute.new(airline: airline, origin_airport: airport_1, destination_airport: airport_4, economy_price: 1, business_price: 2, premium_economy_price: 3).save(validate: false)
    route_2 = AirlineRoute.last
    AirlineRouteRevenue.new(airline_route_id: route_2.id, revenue: 100, exclusive_economy_revenue: 100, exclusive_premium_economy_revenue: 2, exclusive_business_revenue: 3, business_pax: 1, economy_pax: 2, premium_economy_pax: 1).save(validate: false)
    AirplaneRoute.new(route: route_2, airplane: airplane_2, frequencies: 1, flight_cost: 1, block_time_mins: 1).save(validate: false)
    AirlineRoute.new(airline: airline, origin_airport: airport_1, destination_airport: airport_3, economy_price: 1, business_price: 2, premium_economy_price: 3).save(validate: false)

    visit game_airline_routes_path(game, airline)

    expect(page).to have_link route_1.name
    expect(page).to have_link route_2.name

    click_link route_2.name

    expect(page).to have_content route_2.name
    expect(page).not_to have_content route_1.name
    expect(page).to have_content "#{airline.name} pricing on #{route_2.name}"
  end
end
