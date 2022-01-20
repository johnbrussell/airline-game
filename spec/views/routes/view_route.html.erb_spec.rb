require "rails_helper"
require "capybara/rspec"

RSpec.describe "routes/view_route", type: :feature do
  before(:each) do
    nauru = Fabricate(:market, name: "Nauru", country: "Nauru")
    funafuti = Fabricate(:market, name: "Funafuti", country: "Tuvalu")
    Fabricate(:airport, market: nauru, iata: "INU")
    Fabricate(:airport, market: funafuti, iata: "FUN")
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
    visit game_view_route_path(game, params: { origin_id: Airport.find_by(iata: "FUN"), destination_id: Airport.find_by(iata: "FUN")})

    expect(page).to have_content "View a different route"

    click_link "View a different route"

    expect(page).to have_content "Select a route to view"
  end

  it "displays the route in alphabetical order" do
    inu = Airport.find_by(iata: "INU")
    fun = Airport.find_by(iata: "FUN")

    game = Fabricate(:game)

    visit game_view_route_path(game, params: { origin_id: inu.id, destination_id: fun.id })

    expect(page).to have_content "FUN - INU"

    visit game_view_route_path(game, params: { origin_id: fun.id, destination_id: inu.id })

    expect(page).to have_content "FUN - INU"
  end
end
