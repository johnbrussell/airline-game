require "rails_helper"
require "capybara/rspec"

RSpec.describe "airplanes/show", type: :feature do
  let(:game) { Fabricate(:game) }
  let(:fun) { Fabricate(:airport, iata: "FUN") }
  let(:inu) { Fabricate(:airport, iata: "INU", market: fun.market) }
  let(:airline) { Fabricate(:airline, game_id: game.id, is_user_airline: true, base_id: fun.market.id) }
  let(:family) { Fabricate(:aircraft_family) }
  let(:airplane) { Fabricate(:airplane, aircraft_family: family, operator_id: airline.id, base_country_group: airline.base.country_group, business_seats: 0, economy_seats: 2, premium_economy_seats: 1) }

  context "viewing the page" do
    it "links back to the game homepage" do
      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_link "Return to game overview"

      click_link "Return to game overview"

      expect(page).to have_content "Airline Game Home"
    end

    it "links back to the airline fleet page" do
      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_link "Return to #{airline.name} overview"

      click_link "Return to #{airline.name} overview"

      expect(page).to have_content "#{airline.name}"
      expect(page).to have_content "Based in"
    end

    it "links back to the airline page" do
      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_link "Return to #{airline.name} fleet page"

      click_link "Return to #{airline.name} fleet page"

      expect(page).to have_content "#{airline.name} operates 1 airplane"
      expect(page).to have_content "Upcoming deliveries"
    end

    it "shows information about the airplane" do
      airplane.aircraft_model.update(price: 1000)

      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_content "#{airplane.model.family.manufacturer} #{airplane.model.name}"
      expect(page).to have_content "0 business seats"
      expect(page).to have_content "1 premium economy seat"
      expect(page).to have_content "2 economy seats"
      expect(page).to have_content "#{airline.name} owns this airplane"
      expect(page).to have_content "Value: $1,000.00"
      expect(page).to have_content "This airplane is utilized 0.0 hours per day"

      date = Date.tomorrow
      airplane.update(lease_expiry: date, lease_rate: 10)
      AirlineRoute.new(origin_airport: fun, destination_airport: inu, distance: 1, economy_price: 1, business_price: 3, premium_economy_price: 2, airline: airline).save(validate: false)
      AirplaneRoute.new(airline_route_id: AirlineRoute.last.id, frequencies: 1, flight_cost: 11, block_time_mins: 60, airplane_id: airplane.id).save(validate: false)
      AirlineRouteRevenue.new(airline_route_id: AirlineRoute.last.id, revenue: 4, business_pax: 0, economy_pax: 2, premium_economy_pax: 1).save(validate: false)

      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_content "#{airline.name} has leased this airplane through #{date}"
      expect(page).to have_content "FUN - INU: 1 weekly flight. $\n-1.00\ndaily profits"
      expect(page).to have_content "Spending $10.00 daily to lease"
    end
  end
end
