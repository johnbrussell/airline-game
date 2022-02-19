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
    visit game_view_route_path(game, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "FUN")})

    expect(page).to have_content "FUN - FUN"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end

  it "has a link to view a different route" do
    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "TIA", base_id: Market.last.id)
    visit game_view_route_path(game, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "FUN")})

    expect(page).to have_content "View a different route"

    click_link "View a different route"

    expect(page).to have_content "Select a route to view"
  end

  it "displays the route in alphabetical order" do
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")

    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, name: "TIA", base_id: inu.market.id)

    visit game_view_route_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "FUN - INU"

    visit game_view_route_path(game, params: { origin_id: fun.id, destination_id: inu.id })

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

    visit game_view_route_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "1000 miles"
    expect(page).to have_content "At current demand levels, this route can support up to:"
    expect(page).to have_content "$400.00 per week in economy class revenue"
    expect(page).to have_content "$200.00 per week in premium economy class revenue"
    expect(page).to have_content "$100.00 per week in business class revenue"
    expect(page).to have_button "Add or reduce flights on route"
    expect(page).not_to have_content "#{airline.name} cannot fly this route due to political restrictions"

    click_button "Add or reduce flights on route"

    expect(page).to have_link "Return to route overview"
    expect(page).to have_content "Adjust service on FUN - INU"

    click_link "Return to route overview"

    expect(page).to have_content "FUN - INU"
    expect(page).to have_content "1000 miles"
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

    visit game_view_route_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "TIA has 1 available slot at INU"
    expect(page).to have_content "TIA has 4 available slots at FUN"
  end

  it "links to the origin and destination" do
    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, base_id: Market.last.id)
    visit game_view_route_path(game, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "INU")})

    expect(page).to have_content "FUN - INU"

    expect(page).to have_content "View FUN"
    click_link "View FUN"

    expect(page).to have_content "Funafuti (FUN)"

    visit game_view_route_path(game, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "INU")})

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

    visit game_view_route_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).not_to have_button "Add or reduce flights on route"
    expect(page).to have_content "#{airline.name} cannot fly this route due to political restrictions"
  end
end
