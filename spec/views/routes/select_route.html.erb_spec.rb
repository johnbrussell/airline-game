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
    inu = Fabricate(:airport, market: nauru, iata: "INU")
    fun = Fabricate(:airport, market: funafuti, iata: "FUN")
    tbu = Fabricate(:airport, market: nukualofa, iata: "TBU")
    apw = Fabricate(:airport, market: apia, iata: "APW")

    game = Fabricate(:game)
    Fabricate(:airline, is_user_airline: true, game_id: game.id, base_id: apia.id)

    visit game_select_route_path(game)

    expect(page).to have_content "Select a route to view"

    select("INU - Nauru, Nauru", from: "origin_id")
    select("FUN - Funafuti, Tuvalu", from: "destination_id")

    click_on "Go"

    expect(page).to have_content "FUN - INU"
  end
end
