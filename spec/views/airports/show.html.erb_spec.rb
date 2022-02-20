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
      cash_on_hand: 10000000.0,
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
    Airport.create!(iata: "INU", market: nauru, runway: 10000, elevation: 1, start_gates: 1, easy_gates: 1, latitude: 1, longitude: 1)
    Population.create!(population: 1000000, year: 2000, market_id: boston.id)
    Population.create!(population: 100000, year: 2000, market_id: nauru.id)
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
    expect(page).to have_content "The cost to lease a slot is $#{Calculation::SlotRent.calculate(Airport.find_by(iata: "INU"), Game.last).round(2)} per #{Slot::LEASE_TERM_DAYS} days."
    expect(page).to have_content "The cost to build a new gate is $100,000,000.00."
    expect(page).to have_content "A Air has $10,000,000.00 available."

    visit game_airport_path(Game.last, Airport.find_by(iata: "BOS"))

    expect(page).to have_content "United States"
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
      expect(page).to have_content "A Air has 1 slot"
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

  it "shows information about airline slot holdings at the airport" do
    game = Game.last
    airline = Airline.last
    other_airline = Fabricate(:airline, name: "B Air", base_id: Market.find_by(name: "Boston").id, game_id: game.id)
    gates = Gates.create!(current_gates: 1, airport: Airport.find_by(iata: "INU"), game: game)
    Slot.create!(gates_id: gates.id, lessee_id: airline.id)
    Slot.create!(gates_id: gates.id, lessee_id: other_airline.id)
    Slot.create!(gates_id: gates.id, lessee_id: other_airline.id)

    allow(Slot).to receive(:num_used).and_return 10000000000
    allow(Slot).to receive(:num_used).with(airline, Airport.find_by(iata: "INU")).and_return 0
    allow(Slot).to receive(:num_used).with(other_airline, Airport.find_by(iata: "INU")).and_return 1
    expect(Airline).to receive(:at_airport).with(Airport.find_by(iata: "INU"), game).and_return [airline, other_airline]

    visit game_airport_path(game, Airport.find_by(iata: "INU"))

    expect(page).to have_content "Slot holdings and usage"
    expect(page).to have_content "#{airline.name} has 1 slot (0 used)"
    expect(page).to have_content "#{other_airline.name} has 2 slots (1 used)"
  end
end
