require "rails_helper"
require "capybara/rspec"

RSpec.describe "routes/select_route", type: :feature do
  it "has a link back to the game homepage" do
    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id)
    visit game_select_route_path(game)

    expect(page).to have_content "Select a route to view"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end

  it "has a link back to the game homepage" do
    nauru = Fabricate(:market, name: "Nauru", country: "Nauru")
    funafuti = Fabricate(:market, name: "Funafuti", country: "Tuvalu")
    nukualofa = Fabricate(:market, name: "Nukualofa", country: "Tonga")
    apia = Fabricate(:market, name: "Apia", country: "Samoa")
    inu = Fabricate(:airport, market: nauru, iata: "INU", municipality: "Yaren")
    fun = Fabricate(:airport, market: funafuti, iata: "FUN", municipality: nil)
    tbu = Fabricate(:airport, market: nukualofa, iata: "TBU")
    apw = Fabricate(:airport, market: apia, iata: "APW")
    Population.create!(market_id: funafuti.id, year: 2020, population: 10000)
    Population.create!(market_id: nauru.id, year: 2000, population: 14000)
    Population.create!(market_id: nukualofa.id, year: 1950, population: 1000)
    Population.create!(market_id: apia.id, year: 1950, population: 1000)
    Tourists.create!(market_id: nauru.id, year: 1999, volume: 100)
    Tourists.create!(market_id: funafuti.id, year: 2020, volume: 2700)
    Tourists.create!(market_id: nukualofa.id, year: 2022, volume: 20000)
    Tourists.create!(market_id: apia.id, year: 2022, volume: 20000)

    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, base_id: apia.id)

    visit game_select_route_path(game)

    expect(page).to have_content "Select a route to view"

    select("INU - Yaren, Nauru", from: "origin_id")
    select("FUN - Funafuti, Tuvalu", from: "destination_id")

    click_on "Go"

    expect(page).to have_content "FUN - INU"
  end
end
