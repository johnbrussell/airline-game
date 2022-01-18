require "rails_helper"
require "capybara/rspec"

RSpec.describe "airports/show", type: :feature do
  before(:each) do
    game = Game.create!(
      current_date: Date.today,
      start_date: Date.yesterday,
      end_date: Date.tomorrow,
    )
    Airline.create!(
      game_id: game.id,
      name: "A Air",
      cash_on_hand: 10000000,
      base_id: 1,
      is_user_airline: true,
    )
    boston = Market.create!(
      name: "Boston",
      country: "United States",
      country_group: "United States",
      income: 100,
    )
    nauru = Market.create!(
      name: "Nauru",
      country: "Nauru",
      country_group: "Nauru",
      income: 100,
    )
    Airport.create!(iata: "BOS", market: boston, runway: 10000, elevation: 2, start_gates: 2, easy_gates: 100, latitude: 1, longitude: 1)
    Airport.create!(iata: "INU", market: nauru, runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 1, longitude: 1)
    Population.create!(population: 1000000, year: 2000, market_id: boston.id)
    Population.create!(population: 10000, year: 2000, market_id: nauru.id)
    Tourists.create!(volume: 100000, year: 2000, market_id: boston.id)
    Tourists.create!(volume: 1000, year: 2000, market_id: nauru.id)
  end

  it "shows information about the airport" do
    visit game_airport_path(Game.last, Airport.find_by(iata: "INU"))

    expect(page).to have_content "Runway: 10000 feet"
    expect(page).to have_content "Elevation: 1 foot"

    expect(page).to have_content "1 gate"
    expect(page).to have_content "#{Gates::SLOTS_PER_GATE} slots (#{Gates::SLOTS_PER_GATE} available)"
    expect(page).to have_content "A Air has 0 slots"
  end

  it "correctly pluralizes information about the airport" do
    visit game_airport_path(Game.last, Airport.find_by(iata: "BOS"))

    expect(page).to have_content "Elevation: 2 feet"

    expect(page).to have_content "2 gates"
    expect(page).to have_content "#{Gates::SLOTS_PER_GATE * 2} slots (#{Gates::SLOTS_PER_GATE * 2} available)"
  end

  it "has a link back to the game homepage" do
    visit game_airport_path(Game.last, Airport.find_by(iata: "INU"))

    expect(page).to have_content "Nauru (INU)"

    click_link "Return to game overview"

    expect(page).to have_content "Airline Game Home"
  end

  it "has a link back to airport selection" do
    visit game_airport_path(Game.last, Airport.find_by(iata: "INU"))

    expect(page).to have_content "Nauru (INU)"

    click_link "View a different airport"

    select "BOS - Boston, United States"

    click_on "Go"

    expect(page).to have_content "BOS"
  end

  it "does not have a link to other airports when there are no other airports" do
    visit game_airport_path(Game.last, Airport.find_by(iata: "INU"))

    expect(page).to have_content "Nauru (INU)"
    expect(page).not_to have_content "View a different Nauru airport:"
  end

  it "has a link to other market airports" do
    pvd = Airport.create!(iata: "PVD", market: Market.find_by(name: "Boston"), runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 1, longitude: 1)
    visit game_airport_path(Game.last, pvd)

    expect(page).to have_content "Boston (PVD)"
    expect(page).to have_content "Other Boston airport:"

    click_link "BOS"

    expect(page).to have_content "Boston (BOS)"
  end

  it "the link to other market airports pluralizes correctly" do
    pvd = Airport.create!(iata: "PVD", market: Market.find_by(name: "Boston"), runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 1, longitude: 1)
    Airport.create!(iata: "MHT", market: Market.find_by(name: "Boston"), runway: 10000, elevation: 1, start_gates: 1, easy_gates: 100, latitude: 1, longitude: 1)
    visit game_airport_path(Game.last, pvd)

    expect(page).to have_content "Boston (PVD)"
    expect(page).to have_content "Other Boston airports:"

    click_link "MHT"

    expect(page).to have_content "Boston (MHT)"

    click_link "BOS"

    expect(page).to have_content "Boston (BOS)"

    click_link "PVD"

    expect(page).to have_content "Boston (PVD)"
  end

  context "building a gate" do
    it "has a button to build a gate" do
      visit game_airport_path(Game.last, Airport.find_by(iata: "BOS"))

      expect(page).to have_content "2 gates"
      expect(page).to have_content "A Air has 0 slots"

      click_button "Build a gate"

      expect(page).to have_content "3 gates"
      expect(page).to have_content "A Air has #{Gates::SLOTS_PER_GATE} slots"
    end

    it "shows an error when building a gate fails" do
      Airline.last.update(cash_on_hand: 0)

      visit game_airport_path(Game.last, Airport.find_by(iata: "BOS"))

      expect(page).to have_content "2 gates"
      expect(page).to have_content "A Air has 0 slots"

      click_button "Build a gate"

      expect(page).to have_content "2 gates"
      expect(page).to have_content "A Air has 0 slots"
      expect(page).to have_content "Airline cash on hand not sufficient to build"
    end
  end

  context "leasing a slot" do
    it "has a button to lease a slot" do
      visit game_airport_path(Game.last, Airport.find_by(iata: "INU"))

      expect(page).to have_content "#{Gates::SLOTS_PER_GATE} slots (#{Gates::SLOTS_PER_GATE} available)"
      expect(page).to have_content "A Air has 0 slots"

      click_button "Lease a slot"

      expect(page).to have_content "#{Gates::SLOTS_PER_GATE} slots (#{Gates::SLOTS_PER_GATE - 1} available)"
      expect(page).to have_content "A Air has 1 slots"
    end

    it "shows an error when leasing a slot fails" do
      Airline.last.update(cash_on_hand: 0)

      visit game_airport_path(Game.last, Airport.find_by(iata: "INU"))

      expect(page).to have_content "#{Gates::SLOTS_PER_GATE} slots (#{Gates::SLOTS_PER_GATE} available)"
      expect(page).to have_content "A Air has 0 slots"

      click_button "Lease a slot"

      expect(page).to have_content "#{Gates::SLOTS_PER_GATE} slots (#{Gates::SLOTS_PER_GATE} available)"
      expect(page).to have_content "A Air has 0 slots"
      expect(page).to have_content "Airline cash on hand not sufficient to lease"
    end
  end
end
