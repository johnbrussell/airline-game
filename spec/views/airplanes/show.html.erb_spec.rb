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

      expect(page).to have_content game.current_date_in_words

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

      expect(page).to have_button "Change"

      click_button "Change"

      expect(page).to have_content "Change aircraft configuration"
    end

    it "links to an aircraft configuration change page" do
      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_link "Return to #{airline.name} fleet page"

      click_link "Return to #{airline.name} fleet page"

      expect(page).to have_content "#{airline.name} operates 1 airplane"
      expect(page).to have_content "Upcoming deliveries"
    end

    it "shows information about the airplane" do
      airplane.aircraft_model.update(price: 1000)
      airplane.update(construction_date: game.current_date + 1.day)

      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_content "#{airplane.model.family.manufacturer} #{airplane.model.name}"
      expect(page).to have_content "0 business seats"
      expect(page).to have_content "1 premium economy seat"
      expect(page).to have_content "2 economy seats"
      expect(page).to have_content "#{airline.name} owns this airplane"
      expect(page).to have_content "$500 due at delivery"
      expect(page).not_to have_content "Value: $1,000.00"
      expect(page).not_to have_content "Daily maintenance costs: $"
      expect(page).not_to have_content "This airplane is utilized 0.0 hours per day"
      expect(page).to have_content "Takeoff length: #{airplane.model.takeoff_distance} feet"
      expect(page).to have_content "Range: #{airplane.model.max_range} miles"
      expect(page).to have_content "Fuel burn: #{airplane.model.fuel_burn} gallons per hour"
      expect(page).to have_content "To be delivered #{airplane.construction_date}"
      expect(page).not_to have_content "Including maintenance and ownership costs, this airplane earns $"
      expect(page).to have_content "Maximum seats: #{airplane.model.max_economy_seats}"

      date = Date.tomorrow
      airplane.update(lease_expiry: date, lease_rate: 10, construction_date: game.current_date)

      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_content "This airplane is utilized 0.0 hours per day"

      AirlineRoute.new(origin_airport: fun, destination_airport: inu, economy_price: 1, business_price: 3, premium_economy_price: 2, airline: airline).save(validate: false)
      AirplaneRoute.new(airline_route_id: AirlineRoute.last.id, frequencies: 1, flight_cost: 11, block_time_mins: 60, airplane_id: airplane.id).save(validate: false)
      AirlineRouteRevenue.new(airline_route_id: AirlineRoute.last.id, revenue: 4, exclusive_economy_revenue: 3.54, exclusive_business_revenue: 1, exclusive_premium_economy_revenue: 2, business_pax: 0, economy_pax: 2, premium_economy_pax: 1).save(validate: false)

      visit game_airline_airplane_path(game, airline, airplane)

      expect(page).to have_content "#{airline.name} has leased this airplane through #{date}"
      expect(page).to have_content "FUN - INU: 1 weekly flight. $\n-0.43\ndaily profits"
      expect(page).to have_content "Leased for $10.00 daily"
      expect(page).to have_content "Constructed #{airplane.construction_date}"
      expect(page).to have_content "Daily maintenance costs: $#{airplane.maintenance_cost_per_day.round(2)}"
      expect(page).to have_content "Including maintenance and ownership costs, this airplane earns $\n-10.51\nin profits per day"
      expect(page).to have_content "Value: $1,000.00"
    end
  end
end
