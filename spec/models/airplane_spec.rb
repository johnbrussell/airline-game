require "rails_helper"

RSpec.describe Airplane do
  before(:each) do
    base = Fabricate(:market, name: "Default market")
    Fabricate(:airline, base_id: base.id)
  end

  context "available_new" do
    useful_life_years = 30

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      AircraftManufacturingQueue.create!(game: game, aircraft_family_id: family.id, production_rate: 1)
      AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000,
        max_range: 1200,
        speed: 500,
        fuel_burn: 1500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: 10000000,
        takeoff_distance: 5000,
        useful_life: useful_life_years,
        family: family,
      )
    end

    it "includes only airplanes in the current game that don't currently have operators and have not already been produced" do
      game = Game.last
      queue = AircraftManufacturingQueue.last
      other_game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      other_queue = AircraftManufacturingQueue.create!(game: other_game, aircraft_family_id: 1, production_rate: 1)
      base = Fabricate(:market, name: "A", country: "B", country_group: "United States", income: 100)
      airline = Airline.create!(base_id: base.id, name: "American Aviation", game_id: game.id, cash_on_hand: 100)

      valid_airplane = Airplane.create!(
        base_country_group: "United States",
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        base_country_group: "United States",
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: queue,
        operator_id: airline.id,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        base_country_group: "United States",
        construction_date: game.current_date,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        base_country_group: "United States",
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: other_queue,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )

      actual = Airplane.available_new(game)

      expect(actual.length).to eq 1
      expect(actual).to include valid_airplane
    end
  end

  context "available_used" do
    useful_life_years = 30

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      AircraftManufacturingQueue.create!(game: game, aircraft_family_id: family.id, production_rate: 1)
      AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000,
        max_range: 1200,
        speed: 500,
        fuel_burn: 1500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: 10000000,
        takeoff_distance: 5000,
        useful_life: useful_life_years,
        family: family,
      )
    end

    it "includes only airplanes in the current game that don't currently have operators, have already been produced, and are within their useful life" do
      game = Game.last
      queue = AircraftManufacturingQueue.last
      other_game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      other_queue = AircraftManufacturingQueue.create!(game: other_game, aircraft_family_id: 1, production_rate: 1)
      base = Fabricate(:market, name: "A", country: "B", country_group: "United States", income: 100)
      airline = Airline.create!(base_id: base.id, name: "American Aviation", game_id: game.id, cash_on_hand: 100)

      valid_airplane = Airplane.create!(
        base_country_group: "United States",
        construction_date: game.current_date,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        base_country_group: "United States",
        construction_date: game.current_date,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: queue,
        operator_id: airline.id,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        base_country_group: "United States",
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + useful_life_years.years + 1.day,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        base_country_group: "United States",
        construction_date: game.current_date - useful_life_years.years - 1.day,
        end_of_useful_life: game.current_date - 1.day,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        base_country_group: "United States",
        construction_date: game.current_date,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: other_queue,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )

      actual = Airplane.available_used(game)

      expect(actual.length).to eq 1
      expect(actual).to include valid_airplane
    end
  end

  context "with_operator" do
    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      queue = AircraftManufacturingQueue.create!(game: game, aircraft_family_id: family.id, production_rate: 1)
      model = AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000,
        max_range: 1200,
        speed: 500,
        fuel_burn: 1500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: 10000000,
        takeoff_distance: 5000,
        useful_life: 30,
        family: family,
      )
      base = Fabricate(:market, name: "A", country: "B", country_group: "United States", income: 100)
      airline_1 = Airline.create!(base_id: base.id, name: "American Aviation", game_id: game.id, cash_on_hand: 100)
      airline_2 = Airline.create!(base_id: base.id, name: "American Aviators", game_id: game.id, cash_on_hand: 100)
      Airplane.create!(aircraft_model_id: model.id, aircraft_manufacturing_queue_id: queue.id, base_country_group: "United States", operator_id: airline_2.id, construction_date: Date.tomorrow, end_of_useful_life: Date.tomorrow + 2.days)
    end

    it "only includes planes with the specified operator" do
      model = AircraftModel.last
      queue = AircraftManufacturingQueue.last
      airline_1 = Airline.find_by(name: "American Aviation")
      airplane = Airplane.create!(aircraft_model_id: model.id, aircraft_manufacturing_queue_id: queue.id, base_country_group: "United States", operator_id: airline_1.id, construction_date: Date.tomorrow, end_of_useful_life: Date.tomorrow + 2.days)
      expected = [airplane]

      actual = Airplane.with_operator(airline_1.id)

      expect(actual).to eq expected
    end

    it "works for nil" do
      model = AircraftModel.last
      queue = AircraftManufacturingQueue.last
      airplane = Airplane.create!(aircraft_model_id: model.id, aircraft_manufacturing_queue_id: queue.id, base_country_group: "United States", operator_id: nil, construction_date: Date.tomorrow, end_of_useful_life: Date.tomorrow + 2.days)
      expected = [airplane]

      actual = Airplane.with_operator(nil)

      expect(actual).to eq expected
    end
  end

  context "base_changes_appropriately" do
    it "is true when the base changes appropriately" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family, base_country_group: "Tuvalu")

      expect(subject.valid?).to be true
      expect(subject.update(base_country_group: "Nauru")).to be true
    end

    it "is false when the base changes inappropriately" do
      RivalCountryGroup.create!(country_one: "Nauru", country_two: "Tuvalu")
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family, base_country_group: "Tuvalu")

      expect(subject.valid?).to be true
      expect(subject.update(base_country_group: "Nauru")).to be false
      expect(subject.errors.full_messages).to include "Base country group cannot be changed between rival countries"
    end
  end

  context "based_in_right_country" do
    it "is true when the base matches the operator's" do
      market = Fabricate(:market, country_group: "Tuvalu")
      operator = Fabricate(:airline, base_id: market.id)
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family, base_country_group: "Tuvalu", operator_id: operator.id)

      expect(subject.valid?).to be true
    end

    it "is true when there is no operator" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family, base_country_group: "Tuvalu", operator_id: nil)

      expect(subject.valid?).to be true
    end

    it "is false when the base does not match the operator's" do
      market = Fabricate(:market, country_group: "Nauru")
      operator = Fabricate(:airline, base_id: market.id)
      model = Fabricate(:aircraft_model)
      subject = Airplane.new(base_country_group: "Tuvalu", operator_id: operator.id, aircraft_model_id: model.id)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Base country group different from operator's base"
    end
  end

  context "block_time" do
    it "is calculated correctly" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      expect(subject.block_time(0)).to eq Airplane::MIN_TURN_TIME_MINS + 2 * AircraftModel::MIN_TAXI_TIME_MINS

      subject.aircraft_model.update(speed: 108, floor_space: Airplane::ECONOMY_SEAT_SIZE * 180, num_aisles: 1)
      subject.update(economy_seats: 40 / Airplane::TURN_TIME_MINS_PER_SEAT)

      expect(subject.block_time(69)).to eq 116
    end
  end

  context "block_time_feasible" do
    it "is true when the routes' block time is within reason" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 100, max_range: 100000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)

      subject.reload
      expect(subject.valid?).to be true
    end

    it "is false when the routes' block time is too much" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS + 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)

      allow(Calculation::Distance).to receive(:between_airports).with(fun, inu).and_return(100000)

      subject.reload
      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Airplane routes block time is too high"
    end
  end

  context "can_fly_between?" do
    it "is true when the flight is within the operating specifications of the aircraft" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "INU", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "FUN", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)

      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1) # note this wiggle room in distance means that the takeoff distance is slightly less than 10000
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1)

      expect(subject.can_fly_between?(airport_1, airport_2)).to be true
      expect(subject.can_fly_between?(airport_2, airport_1)).to be true
    end

    it "is false when the runway is too short" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "INU", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "FUN", latitude: 11, longitude: 14, runway: 9996, elevation: 0, market: market)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)

      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1)

      expect(subject.can_fly_between?(airport_1, airport_2)).to be false
      expect(subject.can_fly_between?(airport_2, airport_1)).to be false
    end

    it "is false when the airport is too high" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "INU", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "FUN", latitude: 11, longitude: 14, runway: 9997, elevation: 1, market: market)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)

      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1)

      expect(subject.can_fly_between?(airport_1, airport_2)).to be false
      expect(subject.can_fly_between?(airport_2, airport_1)).to be false
    end

    it "is false when the distance is too great" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "INU", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "FUN", latitude: 11, longitude: 14, runway: 10000, elevation: 0, market: market)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)

      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance - 1)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1)

      expect(subject.can_fly_between?(airport_1, airport_2)).to be false
      expect(subject.can_fly_between?(airport_2, airport_1)).to be false
    end

    it "is false when the route is disconnected from the airplane's other routes" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "INU", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "FUN", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      airport_3 = Fabricate(:airport, iata: "MAJ", latitude: 12, longitude: 14, runway: 9997, elevation: 0, market: market)
      airport_4 = Fabricate(:airport, iata: "TRW", latitude: 13, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)

      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1) # note this wiggle room in distance means that the takeoff distance is slightly less than 10000
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_3.id, destination_airport_id: airport_4.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      AirplaneRoute.new(route: airline_route, airplane: subject, block_time_mins: 100, flight_cost: 1, frequencies: 1).save(validate: false)
      subject.reload

      expect(subject.can_fly_between?(airport_1, airport_2)).to be false
      expect(subject.can_fly_between?(airport_2, airport_1)).to be false
    end
  end

  context "can_fly_routes" do
    it "is true when the airplane can fly all of its routes" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      AirplaneRoute.new(route: airline_route, airplane: subject, block_time_mins: 100, flight_cost: 1, frequencies: 1).save(validate: false)
      subject.reload

      expect(subject.valid?).to be true
    end

    it "is true when the airplane has no routes" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      expect(subject.routes.empty?).to be true
      expect(subject.valid?).to be true
    end

    it "is false when the airplane cannot fly at least one of its routes" do
      market = Fabricate(:market, name: "Pacific")
      airport_1 = Fabricate(:airport, iata: "FUN", latitude: 10, longitude: 13, runway: 11000, elevation: 0, market: market, exclusive_catchment: 32)
      airport_2 = Fabricate(:airport, iata: "INU", latitude: 11, longitude: 14, runway: 9997, elevation: 0, market: market, exclusive_catchment: 32)
      airport_3 = Fabricate(:airport, iata: "TRW", latitude: 10, longitude: 12, runway: 11000, elevation: 0, market: market, exclusive_catchment: 32)
      CabotageException.create!(country: market.country)
      family = Fabricate(:aircraft_family)
      distance = Calculation::Distance.between_airports(airport_1, airport_2)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 10000, max_range: distance + 1)
      subject = Fabricate(:airplane, aircraft_family: family, economy_seats: 1, aircraft_model: model)
      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_3.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      AirplaneRoute.new(route: airline_route, airplane: subject, block_time_mins: 100, flight_cost: 1, frequencies: 1).save(validate: false)
      subject.reload

      expect(subject.valid?).to be true

      airline_route = AirlineRoute.create!(origin_airport_id: airport_1.id, destination_airport_id: airport_2.id, economy_price: 1, premium_economy_price: 2, business_price: 3, airline: Airline.last)
      AirplaneRoute.new(route: airline_route, airplane: subject, block_time_mins: 100, flight_cost: 1, frequencies: 1).save(validate: false)
      airport_2.update!(runway: 9996)
      subject.reload

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Routes are not all able to be flown by the aircraft"
    end
  end

  context "daily_profit" do
    it "calculates correctly" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, speed: 1000, takeoff_distance: 100, max_range: 1000000, price: 1000)
      lease_rate = 1
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group, lease_rate: lease_rate, business_seats: 1, economy_seats: 1, premium_economy_seats: 1)
      subject.update(construction_date: subject.game.current_date)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)

      allow(Calculation::Distance).to receive(:between_airports).with(fun, inu).and_return 100

      flight_cost = 1

      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: flight_cost,
        airplane: subject,
        route: route,
      ).save(validate: false)
      AirlineRouteRevenue.new(airline_route: route, business_pax: 1, economy_pax: 1, premium_economy_pax: 1, revenue: 9, exclusive_business_revenue: 9, exclusive_premium_economy_revenue: 0, exclusive_economy_revenue: 8.99).save!
      subject.reload

      maintenance = subject.maintenance_cost_per_day

      round_trip_revenue = 9.0
      days_in_week = 7.0

      assert_in_epsilon subject.daily_profit, round_trip_revenue / days_in_week - flight_cost / days_in_week - lease_rate - maintenance, 0.000000001
    end
  end

  context "has_operator?" do
    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(name: "737", manufacturer: "Boeing", country_group: "United States")
      AircraftManufacturingQueue.create!(game: game, aircraft_family_id: family.id, production_rate: 1)
      AircraftModel.create!(
        name: "737-300",
        production_start_year: 1980,
        floor_space: 1000,
        max_range: 100,
        speed: 500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: 100000000,
        takeoff_distance: 6000,
        useful_life: 30,
        fuel_burn: 100,
        family: family,
      )
    end

    it "is true when the airplane is owned" do
      game = Game.last
      base = Fabricate(:market, name: "A", country: "B", country_group: "United States", income: 100)
      airline = Airline.create!(base_id: base.id, name: "American Aviation", game_id: game.id, cash_on_hand: 100)
      subject = Airplane.create!(
        base_country_group: "United States",
        operator_id: airline.id,
        construction_date: Date.today,
        end_of_useful_life: Date.tomorrow,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        aircraft_model: AircraftModel.last,
      )

      expect(subject.has_operator?).to be true
    end

    it "is false when the airplane is not owned" do
      subject = Airplane.create!(
        base_country_group: "United States",
        operator_id: nil,
        construction_date: Date.today,
        end_of_useful_life: Date.tomorrow,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        aircraft_model: AircraftModel.last,
      )

      expect(subject.has_operator?).to be false
    end
  end

  context "has_time_to_fly?" do
    it "is true when the airplane has time to fly the requested distance" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, speed: 1000, takeoff_distance: 100, max_range: 1000000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)

      allow(Calculation::Distance).to receive(:between_airports).with(fun, inu).and_return 100

      round_trip_block_time = subject.round_trip_block_time(100)
      max_frequencies = (Airplane::MAX_TOTAL_BLOCK_TIME_MINS / round_trip_block_time).floor

      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      frequencies = max_frequencies - 1
      AirplaneRoute.new(
        block_time_mins: (round_trip_block_time * frequencies).round,
        frequencies: frequencies,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      subject.reload

      expect(subject.has_time_to_fly?(100)).to be true
    end

    it "is false when the airplane does not have time to fly the requested distance" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, speed: 1000, takeoff_distance: 100, max_range: 1000000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)

      allow(Calculation::Distance).to receive(:between_airports).with(fun, inu).and_return 100

      round_trip_block_time = subject.round_trip_block_time(100)
      max_frequencies = (Airplane::MAX_TOTAL_BLOCK_TIME_MINS / round_trip_block_time).floor

      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      frequencies = max_frequencies
      AirplaneRoute.new(
        block_time_mins: round_trip_block_time * frequencies,
        frequencies: frequencies,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      subject.reload

      expect(subject.has_time_to_fly?(100)).to be false
    end
  end

  context "legroom_reputation" do
    it "is equivalent to the square root of the percentage of the floor space that is unused" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, family: family, floor_space: Airplane::ECONOMY_SEAT_SIZE * 4)
      subject = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, economy_seats: 1)

      expect(subject.legroom_reputation).to eq Math.sqrt(0.75)

      subject.update(economy_seats: 4)

      expect(subject.legroom_reputation).to eq 0

      subject.update(economy_seats: 0)

      expect(subject.legroom_reputation).to eq 1
    end
  end

  context "maintenance_cost_per_day" do
    it "is the aircraft model's maintenance rate when the airplane is unique in its family" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      subject.update(construction_date: subject.game.current_date)

      expect(subject.maintenance_cost_per_day).to eq subject.aircraft_model.maintenance_cost_per_day(0)
    end

    it "decreases when another family member is added" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, family: family)
      other_model = Fabricate(:aircraft_model, family: family)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      subject.update(construction_date: subject.game.current_date)

      expect(subject.maintenance_cost_per_day).to eq subject.aircraft_model.maintenance_cost_per_day(0)

      Fabricate(:airplane, aircraft_family: family, aircraft_model: other_model)
      subject.reload

      expect(subject.maintenance_cost_per_day).to be < subject.aircraft_model.maintenance_cost_per_day(0)
    end

    it "hits the maximum discount when there are NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE planes in the family" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, family: family)
      other_model = Fabricate(:aircraft_model, family: family)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      subject.update(construction_date: subject.game.current_date)

      expect(subject.maintenance_cost_per_day).to eq subject.aircraft_model.maintenance_cost_per_day(0)

      (1..(Airplane::NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE - 1)).each do
        Fabricate(:airplane, aircraft_family: family, aircraft_model: other_model)
      end
      subject.reload

      expect(subject.send(:num_in_family)).to eq Airplane::NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE
      expect(subject.maintenance_cost_per_day).to eq subject.aircraft_model.maintenance_cost_per_day(0) * Airplane::MIN_MAINTENANCE_RATE
    end

    it "does not exceed the the maximum discount" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, family: family)
      other_model = Fabricate(:aircraft_model, family: family)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      subject.update(construction_date: subject.game.current_date)

      expect(subject.maintenance_cost_per_day).to eq subject.aircraft_model.maintenance_cost_per_day(0)

      (0..(Airplane::NUM_IN_FAMILY_FOR_MIN_MAINTENANCE_RATE + 1)).each do
        Fabricate(:airplane, aircraft_family: family, aircraft_model: other_model)
      end
      subject.reload

      expect(subject.maintenance_cost_per_day).to eq subject.aircraft_model.maintenance_cost_per_day(0) * Airplane::MIN_MAINTENANCE_RATE
    end
  end

  context "operator_changes_appropriately" do
    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0, aircraft_family_id: family.id)
      model = AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000,
        max_range: 1200,
        speed: 500,
        fuel_burn: 1500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: 1000,
        takeoff_distance: 5000,
        useful_life: 30,
        family: family,
      )
      Airplane.create!(
        base_country_group: "United States",
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 1,
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + 1.year,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model_id: model.id,
      )
    end

    it "is true when buying an airplane" do
      game = Game.last
      base = Fabricate(:market, name: "A", country: "B", country_group: "United States", income: 100)
      airline = Airline.create!(base_id: base.id, name: "American Aviation", game_id: game.id, cash_on_hand: 100)
      subject = Airplane.last
      expect(subject.update(operator_id: airline.id)).to be true
    end

    it "is true when selling an airplane" do
      game = Game.last
      base = Fabricate(:market, name: "A", country: "B", country_group: "United States", income: 100)
      airline = Airline.create!(base_id: base.id, name: "American Aviation", game_id: game.id, cash_on_hand: 100)
      subject = Airplane.last
      subject.update(operator_id: airline.id)

      expect(subject.update(operator_id: nil)).to be true
    end

    it "is true when updating an unowned airplane" do
      subject = Airplane.last
      expect(subject.update(economy_seats: 2)).to be true
    end

    it "is true when updating an owned airplane" do
      game = Game.last
      base = Fabricate(:market, name: "A", country: "B", country_group: "United States", income: 100)
      airline = Airline.create!(base_id: base.id, name: "American Aviation", game_id: game.id, cash_on_hand: 100)
      subject = Airplane.last
      subject.update(operator_id: airline.id)

      expect(subject.update(economy_seats: 2)).to be true
    end

    it "is false when selling an airplane from one airline to another" do
      game = Game.last
      base = Fabricate(:market, name: "A", country: "B", country_group: "United States", income: 100)
      airline = Airline.create!(base_id: base.id, name: "American Aviation", game_id: game.id, cash_on_hand: 100)
      other_airline = Airline.create!(base_id: base.id, name: "American Aviators", game_id: game.id, cash_on_hand: 100)
      subject = Airplane.last
      subject.update(operator_id: airline.id)

      expect(subject.update(operator_id: other_airline.id)).to be false
      expect(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include "operator_id cannot be changed from one airline directly to another; must be put on the market first"
    end

    it "is false when selling an airplane that has routes" do
      game = Game.last
      base = Fabricate(:market, name: "A", country: "B", country_group: "United States", income: 100)
      airline = Airline.create!(base_id: base.id, name: "American Aviation", game_id: game.id, cash_on_hand: 100)
      subject = Airplane.last
      subject.update(operator_id: airline.id)

      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      subject.reload

      expect(subject.update(operator_id: nil)).to be false
      expect(subject.errors.full_messages).to include "Operator cannot be changed while airplane is utilized"
    end
  end

  context "new_plane_payment" do
    purchase_price_new = 100000000

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0, aircraft_family_id: family.id)
      model = AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000,
        max_range: 1200,
        speed: 500,
        fuel_burn: 1500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: purchase_price_new,
        takeoff_distance: 5000,
        useful_life: 30,
        family: family,
      )
      Airplane.create!(
        base_country_group: "United States",
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 1,
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + 1.year,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model_id: model.id,
      )
    end

    it "is the rounded price of the aircraft model when the plane has not been built" do
      subject = Airplane.last

      expect(subject.new_plane_payment).to eq 50000000
    end
  end

  context "num_in_family" do
    it "includes the subject" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      expect(subject.send(:num_in_family)).to eq 1
    end

    it "includes the other planes in the family" do
      family = Fabricate(:aircraft_family)
      other_family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, family: family)
      other_model = Fabricate(:aircraft_model, family: family)
      Fabricate(:airplane, aircraft_family: other_family)
      Fabricate(:airplane, aircraft_family: family, aircraft_model: other_model)
      Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)

      expect(subject.send(:num_in_family)).to eq 3
    end
  end

  context "on_time_reputation" do
    let(:family) { Fabricate(:aircraft_family) }
    let(:model) { Fabricate(:aircraft_model, family: family, speed: 100, num_aisles: 1) }
    let(:origin) { Fabricate(:airport, iata: "ACV") }
    let(:destination) { Fabricate(:airport, market: origin.market, iata: "LAS") }
    let(:airline) { Fabricate(:airline, base_id: origin.market.id) }

    it "is 1 when the airplane is not utilized" do
      expect(Airplane.new.on_time_reputation).to eq 1
    end

    it "is 1 irrespective of utilization when the airplane flies few flights" do
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)

      airline_route = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, economy_price: 1, business_price: 3, premium_economy_price: 2, airline: airline)
      airplane_route_1 = AirplaneRoute.new(airplane: subject, route: airline_route, frequencies: 1, block_time_mins: 1, flight_cost: 1).save(validate: false)

      expect(Calculation::Distance).to receive(:between_airports).with(origin, destination).and_return 200000

      subject.reload

      expect(subject.utilization).to be > Airplane::MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY
      expect(subject.on_time_reputation).to eq 1
    end

    it "is 1 when the airplane is utilized BLOCK_TIME_HOURS_PER_DAY_FOR_GOOD_ON_TIME_PERFORMANCE hours per day" do
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, business_seats: 0, premium_economy_seats: 0)

      airline_route = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, economy_price: 1, business_price: 3, premium_economy_price: 2, airline: airline)
      airplane_route_1 = AirplaneRoute.new(airplane: subject, route: airline_route, frequencies: Airplane::MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY, block_time_mins: 1, flight_cost: 1).save(validate: false)

      expect(Calculation::Distance).to receive(:between_airports).with(origin, destination).and_return 27.40075

      subject.reload

      expect(subject.on_time_reputation).to eq 1
      assert_in_epsilon subject.utilization, Airplane::BLOCK_TIME_HOURS_PER_DAY_FOR_GOOD_ON_TIME_PERFORMANCE, 0.000001
    end

    it "is between 0.1 and 1 when the airplane is utilized less than the maximum" do
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, business_seats: 0, premium_economy_seats: 0)

      airline_route = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, economy_price: 1, business_price: 3, premium_economy_price: 2, airline: airline)
      airplane_route_1 = AirplaneRoute.new(airplane: subject, route: airline_route, frequencies: Airplane::MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY, block_time_mins: 1, flight_cost: 1).save(validate: false)

      expect(Calculation::Distance).to receive(:between_airports).with(origin, destination).and_return 30

      subject.reload

      expect(subject.on_time_reputation).to be < 1
      expect(subject.on_time_reputation).to be > 0.1
      expect(subject.utilization).to be > Airplane::BLOCK_TIME_HOURS_PER_DAY_FOR_GOOD_ON_TIME_PERFORMANCE
      expect(subject.utilization).to be < Airplane::MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY
    end

    it "is 0.1 when the airplane is utilized maximally" do
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, economy_seats: 1, business_seats: 0, premium_economy_seats: 0)

      airline_route = AirlineRoute.create!(origin_airport: origin, destination_airport: destination, economy_price: 1, business_price: 3, premium_economy_price: 2, airline: airline)
      airplane_route_1 = AirplaneRoute.new(airplane: subject, route: airline_route, frequencies: Airplane::MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY, block_time_mins: 1, flight_cost: 1).save(validate: false)

      expect(Calculation::Distance).to receive(:between_airports).with(origin, destination).and_return 286.74603176116
      subject.reload

      assert_in_epsilon subject.on_time_reputation, 0.1, 0.00000001
      assert_in_epsilon subject.utilization, Airplane::MAX_TOTAL_BLOCK_TIME_HOURS_PER_DAY, 0.000001
    end
  end

  context "operator_has_rights_to_plane" do
    let(:market_1) { Fabricate(:market, name: "Nauru") }
    let(:market_2) { Fabricate(:market, name: "Funafuti") }
    let(:airline_1) { Fabricate(:airline, base_id: market_1.id) }
    let(:airline_2) { Fabricate(:airline, base_id: market_2.id) }
    let(:family) { Fabricate(:aircraft_family) }
    let(:model) { Fabricate(:aircraft_model, family: family) }
    let(:queue) { Fabricate(:aircraft_manufacturing_queue) }
    let(:construction_date) { Date.today }
    let(:end_of_useful_life) { construction_date + 1.year }

    it "is valid when the operator is nil and the owner is nil" do
      subject = Airplane.new(operator_id: nil, owner_id: nil, aircraft_model: model, base_country_group: "Nauru", construction_date: construction_date, aircraft_manufacturing_queue: queue, end_of_useful_life: end_of_useful_life)

      expect(subject.valid?).to be true
    end

    it "is valid when the operator is nil and the owner is present" do
      subject = Airplane.new(operator_id: nil, owner_id: airline_1.id, aircraft_model: model, base_country_group: "Nauru", construction_date: construction_date, aircraft_manufacturing_queue: queue, end_of_useful_life: end_of_useful_life)

      expect(subject.valid?).to be true
    end

    it "is valid when the operator is present and the owner is nil" do
      subject = Airplane.new(operator_id: airline_2.id, owner_id: nil, aircraft_model: model, base_country_group: market_2.country_group, construction_date: construction_date, aircraft_manufacturing_queue: queue, end_of_useful_life: end_of_useful_life)

      expect(subject.valid?).to be true
    end

    it "is valid when the operator and owner are present and they match" do
      subject = Airplane.new(operator_id: airline_2.id, owner_id: airline_2.id, aircraft_model: model, base_country_group: market_2.country_group, construction_date: construction_date, aircraft_manufacturing_queue: queue, end_of_useful_life: end_of_useful_life)

      expect(subject.valid?).to be true
    end

    it "is invalid when the operator and owner are present but do not match" do
      subject = Airplane.new(operator_id: airline_1.id, owner_id: airline_2.id, aircraft_model: model)

      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Operator cannot be different from owner_id when airplane is owned by an airline"
    end
  end

  context "purchase_price" do
    purchase_price_new = 100000000

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0, aircraft_family_id: family.id)
      model = AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000,
        max_range: 1200,
        speed: 500,
        fuel_burn: 1500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: purchase_price_new,
        takeoff_distance: 5000,
        useful_life: 30,
        family: family,
      )
      Airplane.create!(
        base_country_group: "United States",
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 1,
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + 1.year,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model_id: model.id,
      )
    end

    it "is the price of the aircraft model when the plane has not been built" do
      subject = Airplane.last

      expect(subject.purchase_price).to eq purchase_price_new
    end

    it "depreciates every day" do
      subject = Airplane.last
      game = Game.last

      linear_decline_per_day = (AircraftModel.last.price - AircraftModel.last.price * AircraftModel::PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE) / (AircraftModel.last.useful_life * AircraftModel::DAYS_PER_YEAR)

      subject.update!(construction_date: game.current_date)
      subject.reload

      expect(subject.purchase_price).to eq purchase_price_new

      subject.update!(construction_date: game.current_date - 1.day)
      subject.reload

      day_2_price = subject.purchase_price

      expect(subject.purchase_price).to be < purchase_price_new
      expect(subject.purchase_price).to be < purchase_price_new - linear_decline_per_day

      subject.update!(construction_date: game.current_date - 2.days)
      subject.reload

      expect(subject.purchase_price).to be < day_2_price
      expect(subject.purchase_price).to be < purchase_price_new - linear_decline_per_day * 2
    end

    it "is very low past the end of its useful life" do
      subject = Airplane.last
      game = Game.last

      subject.update!(construction_date: game.current_date - (AircraftModel::DAYS_PER_YEAR * subject.send(:model).useful_life).days)
      subject.reload

      assert_in_epsilon subject.purchase_price, AircraftModel.last.price * AircraftModel::PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE, 0.001
    end
  end

  context "lease" do
    purchase_price_new = 100000000
    previous_owner_id = 1

    it "returns false if the airline does not have enough money" do
      family = Fabricate(:aircraft_family, country_group: "St. Pierre and Miquelon")
      market = Fabricate(:market, country_group: "Canada")
      subject = Fabricate(:airplane, aircraft_family: family, owner_id: previous_owner_id)
      buyer = Fabricate(:airline, cash_on_hand: 100, base_id: market.id)

      expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq 100
      expect(subject.operator_id).to be nil
      expect(subject.owner_id).to eq 1
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
      expect(subject.lease_expiry).to be nil
      expect(subject.base_country_group).to eq "St. Pierre and Miquelon"
    end

    it "returns false if the plane is already owned by the buyer" do
      family = Fabricate(:aircraft_family)
      buyer = Fabricate(:airline, cash_on_hand: 100000000)
      subject = Fabricate(:airplane, aircraft_family: family, operator_id: buyer.id, base_country_group: buyer.base.country_group, owner_id: buyer.id)

      initial_cash_on_hand = buyer.cash_on_hand

      expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.operator_id).to be buyer.id
      expect(subject.owner_id).to eq buyer.id
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
      expect(subject.lease_expiry).to be nil
    end

    it "returns false if the plane is already owned by another airline" do
      family = Fabricate(:aircraft_family)
      base = Fabricate(:market)
      buyer = Fabricate(:airline, name: "A Air", base_id: base.id, cash_on_hand: 100000000)
      other_airline = Fabricate(:airline, name: "B Air", base_id: base.id)
      subject = Fabricate(:airplane, aircraft_family: family, operator_id: other_airline.id, base_country_group: buyer.base.country_group, owner_id: other_airline.id)

      initial_cash_on_hand = buyer.cash_on_hand

      expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.operator_id).to be buyer.id + 1
      expect(subject.owner_id).to eq other_airline.id
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
      expect(subject.lease_expiry).to be nil
    end

    context "new plane" do
      it "returns true, assigns the plane to the airline, and installs the right number of seats" do
        family = Fabricate(:aircraft_family, country_group: "United States")
        market = Fabricate(:market, country_group: "Nauru")
        buyer = Fabricate(:airline, cash_on_hand: 100000000, base_id: market.id)
        subject = Fabricate(:airplane, aircraft_family: family)
        game = subject.game

        subject.update(construction_date: game.current_date + 1.day)
        subject.reload

        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be true

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to eq initial_cash_on_hand
        expect(subject.operator_id).to eq buyer.id
        expect(subject.owner_id).to be nil
        expect(subject.business_seats).to eq 3
        expect(subject.premium_economy_seats).to eq 4
        expect(subject.economy_seats).to eq 5
        expect(subject.lease_expiry).to eq subject.construction_date + 100.days
        expect(subject.lease_rate).to be > 0
        expect(subject.base_country_group).to eq "Nauru"
      end

      it "returns false if the number of seats requested requires too much square footage" do
        family = Fabricate(:aircraft_family, country_group: "Nauru")
        market = Fabricate(:market, country_group: "Tuvalu")
        subject = Fabricate(:airplane, aircraft_family: family)
        buyer = Fabricate(:airline, cash_on_hand: 100000000, base_id: market.id)

        subject.update(construction_date: subject.game.current_date + 1.day)
        subject.reload

        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.lease(
          airline = buyer,
          length_in_days = 100,
          business_seats = 1,
          premium_economy_seats = 1,
          economy_seats = subject.aircraft_model.floor_space / Airplane::ECONOMY_SEAT_SIZE + 1)
        ).to be false

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to eq initial_cash_on_hand
        expect(subject.operator_id).to be nil
        expect(subject.owner_id).to be nil
        expect(subject.business_seats).to eq 0
        expect(subject.premium_economy_seats).to eq 0
        expect(subject.economy_seats).to eq 0
        expect(subject.lease_expiry).to be nil
        expect(subject.base_country_group).to eq "Nauru"
      end
    end

    context "used plane" do
      it "does not update the seating configuration" do
        family = Fabricate(:aircraft_family, country_group: "United States")
        market = Fabricate(:market, country_group: "Nauru")
        buyer = Fabricate(:airline, cash_on_hand: 100000000, base_id: market.id)
        subject = Fabricate(:airplane, aircraft_family: family, owner_id: previous_owner_id)
        game = subject.game

        subject.update(construction_date: game.current_date)
        subject.reload
        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be true

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to be < initial_cash_on_hand
        expect(subject.operator_id).to eq buyer.id
        expect(subject.owner_id).to be nil
        expect(subject.business_seats).to eq 0
        expect(subject.premium_economy_seats).to eq 0
        expect(subject.economy_seats).to eq 0
        expect(subject.lease_expiry).to eq game.current_date + 100.days
        expect(subject.lease_rate).to be > 0
        expect(subject.base_country_group).to eq "Nauru"
      end
    end
  end

  context "lease_rate_per_day" do
    purchase_price_new = 100000000

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0, aircraft_family_id: family.id)
      model = AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000,
        max_range: 1200,
        speed: 500,
        fuel_burn: 1500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: purchase_price_new,
        takeoff_distance: 5000,
        useful_life: 30,
        family: family,
      )
      Airplane.create!(
        base_country_group: "United States",
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 1,
        construction_date: game.current_date - 1.day,
        end_of_useful_life: game.current_date + 1.year,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model_id: model.id,
      )
    end

    it "is greater than the loss in value over a short time period" do
      subject = Airplane.last

      current_age = 1
      time_period_days = 1

      value_before = subject.send(:value_at_age, 1)
      value_after = subject.send(:value_at_age, current_age + time_period_days)

      lease_rate = time_period_days * subject.lease_rate_per_day(time_period_days)

      expect(lease_rate).to be > 0
      expect(lease_rate).to be > value_before - value_after
    end

    it "is greater than the loss in value over a long time period" do
      subject = Airplane.last
      model = AircraftModel.last

      current_age = 1
      time_period_days = model.useful_life * AircraftModel::DAYS_PER_YEAR - 1

      value_before = subject.send(:value_at_age, current_age)
      value_after = subject.send(:value_at_age, current_age + time_period_days)

      lease_rate = time_period_days * subject.lease_rate_per_day(time_period_days)

      expect(lease_rate).to be > 0
      expect(lease_rate).to be > value_before - value_after
    end

    it "is cheaper for older aircraft" do
      subject = Airplane.last

      lease_length = 1000

      lease_rate_new = subject.lease_rate_per_day(lease_length)

      subject.update!(construction_date: subject.construction_date - 1.day)
      subject.reload

      lease_rate_old = subject.lease_rate_per_day(lease_length)

      expect(lease_rate_new).to be > lease_rate_old
    end

    it "is approximately equal to the value of the aircraft when its length is PERCENT_OF_USEFUL_LIFE_LEASED_FOR_FULL_VALUE percent of the aircraft's useful life" do
      subject = Airplane.last
      model = AircraftModel.last

      lease_length_days = Airplane::PERCENT_OF_USEFUL_LIFE_LEASED_FOR_FULL_VALUE * model.useful_life * AircraftModel::DAYS_PER_YEAR

      lease_rate = subject.lease_rate_per_day(lease_length_days)

      assert_in_epsilon lease_rate, model.price / lease_length_days, 0.001
    end
  end

  context "num_seats" do
    it "is equal to the number of seats on the airplane" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      subject.update(economy_seats: 10, business_seats: 20, premium_economy_seats: 30)

      expect(subject.num_seats).to eq 60
    end
  end

  context "purchase" do
    purchase_price_new = 100000000

    it "returns false if the airline does not have enough money" do
      family = Fabricate(:aircraft_family, country_group: "United States")
      base = Fabricate(:market, country_group: "Europe")
      buyer = Fabricate(:airline, cash_on_hand: 100, base_id: base.id)
      subject = Fabricate(:airplane, aircraft_family: family)

      expect(subject.purchase(airline = buyer, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq 100
      expect(subject.operator_id).to be nil
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
      expect(subject.base_country_group).to eq "United States"
    end

    it "returns false if the plane is already owned by the buyer" do
      family = Fabricate(:aircraft_family)
      buyer = Fabricate(:airline, cash_on_hand: 100000000)
      subject = Fabricate(:airplane, aircraft_family: family, operator_id: buyer.id, base_country_group: buyer.base.country_group)

      initial_cash_on_hand = buyer.cash_on_hand

      expect(subject.purchase(airline = buyer, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.operator_id).to be buyer.id
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
    end

    it "returns false if the plane is already owned by another airline" do
      family = Fabricate(:aircraft_family)
      base = Fabricate(:market)
      buyer = Fabricate(:airline, name: "A Air", base_id: base.id, cash_on_hand: 100000000)
      other_airline = Fabricate(:airline, name: "B Air", base_id: base.id)
      subject = Fabricate(:airplane, aircraft_family: family, operator_id: other_airline.id, base_country_group: other_airline.base.country_group)

      initial_cash_on_hand = buyer.cash_on_hand

      expect(subject.purchase(airline = buyer, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.operator_id).to be buyer.id + 1
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
    end

    context "new" do
      it "returns true, assigns the plane to the airline, installs the right number of seats, and deducts the purchase price from the airline's cash" do
        family = Fabricate(:aircraft_family, country_group: "Tuvalu")
        market = Fabricate(:market, country_group: "Nauru")
        buyer = Fabricate(:airline, cash_on_hand: 100000000, base_id: market.id)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.update(construction_date: subject.game.current_date + 1.day)
        subject.reload

        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.purchase(airline = buyer, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be true

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to eq initial_cash_on_hand - purchase_price_new / 2
        expect(subject.operator_id).to eq buyer.id
        expect(subject.business_seats).to eq 3
        expect(subject.premium_economy_seats).to eq 4
        expect(subject.economy_seats).to eq 5
        expect(subject.base_country_group).to eq "Nauru"
      end

      it "returns false if the number of seats requested requires too much square footage" do
        family = Fabricate(:aircraft_family, country_group: "Tuvalu")
        market = Fabricate(:market, country_group: "Nauru")
        buyer = Fabricate(:airline, cash_on_hand: 100000000, base_id: market.id)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.update(construction_date: subject.game.current_date + 1.day)
        subject.reload

        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.purchase(airline = buyer, business_seats = 1, premium_economy_seats = 1, economy_seats = subject.aircraft_model.floor_space / Airplane::ECONOMY_SEAT_SIZE + 1)).to be false

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to eq initial_cash_on_hand
        expect(subject.operator_id).to be nil
        expect(subject.business_seats).to eq 0
        expect(subject.premium_economy_seats).to eq 0
        expect(subject.economy_seats).to eq 0
        expect(subject.base_country_group).to eq "Tuvalu"
      end
    end

    context "used" do
      it "does not update the seating configuration" do
        family = Fabricate(:aircraft_family, country_group: "Kiribati")
        market = Fabricate(:market, country_group: "Nauru")
        buyer = Fabricate(:airline, cash_on_hand: 100000000, base_id: market.id)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.update(construction_date: subject.game.current_date)
        subject.reload
        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.purchase(airline = buyer, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be true

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to be < initial_cash_on_hand
        expect(subject.operator_id).to eq buyer.id
        expect(subject.business_seats).to eq 0
        expect(subject.premium_economy_seats).to eq 0
        expect(subject.economy_seats).to eq 0
        expect(subject.base_country_group).to eq "Nauru"
      end
    end
  end

  context "range_from_airport" do
    context "percent_of_max_seats_uninstalled" do
      it "is 0 when the seats on the plane are maximized" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
        subject.update(economy_seats: 10)

        expect(subject.send(:percent_of_max_seats_uninstalled)).to eq 0
      end

      it "is 1 when there are no seats on the plane" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.update(economy_seats: 0)

        expect(subject.send(:percent_of_max_seats_uninstalled)).to eq 1
      end

      it "is between 0 and 1 otherwise and increases as seats are added" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.update(economy_seats: 5)

        old_pct = subject.send(:percent_of_max_seats_uninstalled)
        expect(old_pct).to be < 1

        subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
        subject.update(economy_seats: 6)

        new_pct = subject.send(:percent_of_max_seats_uninstalled)
        expect(new_pct).to be < old_pct
        expect(new_pct).to be > 0
      end
    end

    context "range_with_unlimited_runway" do
      it "is the plane's maximum range when seats are maximized" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
        subject.update(economy_seats: 10)

        expect(subject.send(:range_with_unlimited_runway)).to eq subject.aircraft_model.max_range
      end

      it "is more than the plane's maximum range when there are no seats on the plane" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
        subject.update(economy_seats: 0)

        expect(subject.send(:range_with_unlimited_runway)).to eq subject.aircraft_model.max_range * Airplane::EMPTY_PLANE_RANGE_MULTIPLIER
        expect(subject.send(:range_with_unlimited_runway)).to be > subject.aircraft_model.max_range
      end

      it "is more than the plane's maximum range when seats are not maximized" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
        subject.update(economy_seats: 9)

        expect(subject.send(:range_with_unlimited_runway)).to be < subject.aircraft_model.max_range * Airplane::EMPTY_PLANE_RANGE_MULTIPLIER
        expect(subject.send(:range_with_unlimited_runway)).to be > subject.aircraft_model.max_range
      end
    end

    context "seats_elevation_range_constant" do
      it "calculates correctly" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10, takeoff_distance: 2000)
        subject.update(economy_seats: 10)

        expected = 1000 * (2 ** (1/2.0)) * Airplane::TAKEOFF_ELEVATION_MULTIPLIER

        assert_in_epsilon subject.send(:seats_elevation_range_constant, Airplane::ELEVATION_FOR_TAKEOFF_MULTIPLIER), expected, 0.00000001
      end
    end

    context "takeoff_elevation_multiplier" do
      it "is 1 below sea level" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        expect(subject.send(:takeoff_elevation_multiplier, -10000)).to eq 1
      end

      it "is 1 at sea level" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        expect(subject.send(:takeoff_elevation_multiplier, 0)).to eq 1
      end

      it "is between 1 and TAKEOFF_ELEVATION_MULTIPLIER between 0 and ELEVATION_FOR_TAKEOFF_MULTIPLIER feet of elevation" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        expect(subject.send(:takeoff_elevation_multiplier, 1)).to be > 1
        expect(subject.send(:takeoff_elevation_multiplier, Airplane::ELEVATION_FOR_TAKEOFF_MULTIPLIER - 1)).to be > 1
        expect(subject.send(:takeoff_elevation_multiplier, 1)).to be < Airplane::TAKEOFF_ELEVATION_MULTIPLIER
        expect(subject.send(:takeoff_elevation_multiplier, Airplane::ELEVATION_FOR_TAKEOFF_MULTIPLIER - 1)).to be < Airplane::TAKEOFF_ELEVATION_MULTIPLIER
        expect(subject.send(:takeoff_elevation_multiplier, Airplane::ELEVATION_FOR_TAKEOFF_MULTIPLIER - 1)).to be > subject.send(:takeoff_elevation_multiplier, 1)
      end

      it "is TAKEOFF_ELEVATION_MULTIPLIER at ELEVATION_FOR_TAKEOFF_MULTIPLIER feet of elevation" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        expect(subject.send(:takeoff_elevation_multiplier, Airplane::ELEVATION_FOR_TAKEOFF_MULTIPLIER)).to eq Airplane::TAKEOFF_ELEVATION_MULTIPLIER
      end

      it "is greater than TAKEOFF_ELEVATION_MULTIPLIER at more than ELEVATION_FOR_TAKEOFF_MULTIPLIER feet of elevation" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        expect(subject.send(:takeoff_elevation_multiplier, Airplane::ELEVATION_FOR_TAKEOFF_MULTIPLIER) + 1).to be > subject.send(:takeoff_elevation_multiplier, Airplane::ELEVATION_FOR_TAKEOFF_MULTIPLIER)
      end
    end

    context "takeoff_seats_component" do
      root_2 = 2 ** (1/2.0)

      it "is sqrt(2) when seats are maximized" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
        subject.update(economy_seats: 10)

        expect(subject.send(:takeoff_seats_component)).to eq root_2
      end

      it "is 1 when there are no seats on the plane" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
        subject.update(economy_seats: 0)

        expect(subject.send(:takeoff_seats_component)).to eq 1
      end

      it "is somewhere between 1 and sqrt(2) when seats are between 0 and the maximum" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
        subject.update(economy_seats: 5)

        actual_1 = subject.send(:takeoff_seats_component)

        expect(actual_1).to be > 1
        expect(actual_1).to be < root_2

        subject.update(economy_seats: 6)

        expect(subject.send(:takeoff_seats_component)).to be > 1
        expect(subject.send(:takeoff_seats_component)).to be < root_2
        expect(subject.send(:takeoff_seats_component)).to be > actual_1
      end
    end

    it "is equivalent to the plane's unlimited runway range at sea level with maximum seats on a runway equal to the stated maximum takeoff roll" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      airport = Fabricate(:airport, runway: subject.aircraft_model.takeoff_distance, elevation: 0)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 10)

      assert_in_epsilon subject.range_from_airport(airport), subject.aircraft_model.max_range, 0.00000001
    end

    it "is greater than the plane's unlimited runway range when a seat is removed" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      airport = Fabricate(:airport, runway: subject.aircraft_model.takeoff_distance, elevation: 0)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 9)

      expect(subject.range_from_airport(airport)).to be > subject.aircraft_model.max_range
    end

    it "is less than the plane's unlimited runway range when the runway is shorter than the stated maximum takeoff roll" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      airport = Fabricate(:airport, runway: subject.aircraft_model.takeoff_distance - 1, elevation: 0)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 10)

      expect(subject.range_from_airport(airport)).to be < subject.aircraft_model.max_range
    end

    it "is less than the plane's unlimited runway range when the airport is at a greater elevation" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      airport = Fabricate(:airport, runway: subject.aircraft_model.takeoff_distance, elevation: 1)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 10)

      expect(subject.range_from_airport(airport)).to be < subject.aircraft_model.max_range
    end

    it "is zero for unreasonable runways" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      airport = Fabricate(:airport, runway: subject.aircraft_model.takeoff_distance / 2.5, elevation: 0)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)

      expect(subject.range_from_airport(airport)).to eq 0
    end
  end

  context "round_trip_block_time" do
    it "is calculated correctly" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      expect(subject.round_trip_block_time(0)).to eq 2 * (Airplane::MIN_TURN_TIME_MINS + 2 * AircraftModel::MIN_TAXI_TIME_MINS)

      subject.aircraft_model.update(speed: 108, floor_space: Airplane::ECONOMY_SEAT_SIZE * 180, num_aisles: 1)
      subject.update(economy_seats: 40 / Airplane::TURN_TIME_MINS_PER_SEAT)

      expect(subject.round_trip_block_time(69)).to eq 232
    end
  end

  context "routes_connected_with?" do
    it "is true if the airplane has no routes" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      expect(subject.routes_connected_with?("JFK", "LGA")).to be true
    end

    it "is true if the origin and destination provided connect to the airplane's existing routes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)

      expect(subject.routes_connected_with?("INU", "LGA")).to be true
      expect(subject.routes_connected_with?("FUN", "LGA")).to be true
      expect(subject.routes_connected_with?("JFK", "FUN")).to be true
      expect(subject.routes_connected_with?("JFK", "INU")).to be true
    end

    it "is false if the origin and destination provided do not connect to the airplane's existing routes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      subject.reload

      expect(subject.routes_connected_with?("JFK", "LGA")).to be false
    end
  end

  context "routes_connected_without?" do
    it "is true if the airplane has no routes" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      expect(subject.routes_connected_without?("JFK", "LGA")).to be true
    end

    it "is true for a route the airplane doesn't fly" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      subject.reload

      expect(subject.routes_connected_without?("LGA", "JFK")).to be true
    end

    it "is true if the airplane's only route is the origin and destination supplied" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      subject.reload

      expect(subject.routes_connected_without?("INU", "FUN")).to be true
      expect(subject.routes_connected_without?("FUN", "INU")).to be true
    end

    it "is true if the airplane's only routes are the origin and destination supplied and another connected route" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: trw,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      subject.reload

      expect(subject.routes_connected_without?("INU", "FUN")).to be true
      expect(subject.routes_connected_without?("FUN", "INU")).to be true
      expect(subject.routes_connected_without?("FUN", "TRW")).to be true
      expect(subject.routes_connected_without?("TRW", "FUN")).to be true
    end

    it "is false if the origin and destination supplied are a necessary link between the airplane's routes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, takeoff_distance: 1, max_range: 10000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: trw,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: inu,
        destination_airport: maj,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      subject.reload

      expect(subject.routes_connected_without?("INU", "FUN")).to be false
      expect(subject.routes_connected_without?("FUN", "INU")).to be false
    end
  end

  context "seats_fit_on_plane" do
    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      AircraftManufacturingQueue.create!(game: game, production_rate: 0, aircraft_family_id: family.id)
      AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: Airplane::BUSINESS_SEAT_SIZE * 2,
        max_range: 1200,
        speed: 500,
        fuel_burn: 1500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: 100,
        takeoff_distance: 5000,
        useful_life: 30,
        family: family,
      )
    end

    it "is true when the economy seats fit on the plane" do
      subject = Airplane.new(
        base_country_group: "United States",
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: Airplane::BUSINESS_SEAT_SIZE * 2 / Airplane::ECONOMY_SEAT_SIZE,
        construction_date: Game.last.current_date - 1.day,
        end_of_useful_life: Game.last.current_date + 1.year,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        operator_id: nil,
        aircraft_model_id: AircraftModel.last.id,
      )

      expect(subject.save).to be true
    end

    it "is true when the premium economy seats fit on the plane" do
      subject = Airplane.new(
        base_country_group: "United States",
        business_seats: 0,
        premium_economy_seats: Airplane::BUSINESS_SEAT_SIZE * 2 / Airplane::PREMIUM_ECONOMY_SEAT_SIZE,
        economy_seats: 0,
        construction_date: Game.last.current_date - 1.day,
        end_of_useful_life: Game.last.current_date + 1.year,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        operator_id: nil,
        aircraft_model_id: AircraftModel.last.id,
      )

      expect(subject.save).to be true
    end

    it "is true when the business seats fit on the plane" do
      subject = Airplane.new(
        base_country_group: "United States",
        business_seats: 2,
        premium_economy_seats: 0,
        economy_seats: 0,
        construction_date: Game.last.current_date - 1.day,
        end_of_useful_life: Game.last.current_date + 1.year,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        operator_id: nil,
        aircraft_model_id: AircraftModel.last.id,
      )

      expect(subject.save).to be true
    end

    it "is true when the seats fit on the plane" do
      subject = Airplane.new(
        base_country_group: "United States",
        business_seats: 1,
        premium_economy_seats: 1,
        economy_seats: (Airplane::BUSINESS_SEAT_SIZE - Airplane::PREMIUM_ECONOMY_SEAT_SIZE) / Airplane::ECONOMY_SEAT_SIZE,
        construction_date: Game.last.current_date - 1.day,
        end_of_useful_life: Game.last.current_date + 1.year,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        operator_id: nil,
        aircraft_model_id: AircraftModel.last.id,
      )

      expect(subject.save).to be true
    end

    it "is false when there are too many economy seats" do
      subject = Airplane.new(
        base_country_group: "United States",
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: Airplane::BUSINESS_SEAT_SIZE * 2 / Airplane::ECONOMY_SEAT_SIZE + 1,
        construction_date: Game.last.current_date - 1.day,
        end_of_useful_life: Game.last.current_date + 1.year,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        operator_id: nil,
        aircraft_model_id: AircraftModel.last.id,
      )

      expect(subject.save).to be false
      expect(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include "seats require more total floor space than available on airplane"
    end

    it "is false when there are too many premium economy seats" do
      subject = Airplane.new(
        base_country_group: "United States",
        business_seats: 0,
        premium_economy_seats: Airplane::BUSINESS_SEAT_SIZE * 2 / Airplane::PREMIUM_ECONOMY_SEAT_SIZE + 1,
        economy_seats: 0,
        construction_date: Game.last.current_date - 1.day,
        end_of_useful_life: Game.last.current_date + 1.year,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        operator_id: nil,
        aircraft_model_id: AircraftModel.last.id,
      )

      expect(subject.save).to be false
      expect(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include "seats require more total floor space than available on airplane"
    end

    it "is false when there are too many business seats" do
      subject = Airplane.new(
        base_country_group: "United States",
        business_seats: 3,
        premium_economy_seats: 0,
        economy_seats: 0,
        construction_date: Game.last.current_date - 1.day,
        end_of_useful_life: Game.last.current_date + 1.year,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        operator_id: nil,
        aircraft_model_id: AircraftModel.last.id,
      )

      expect(subject.save).to be false
      expect(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include "seats require more total floor space than available on airplane"
    end

    it "is false when the seats do not fit on the plane" do
      subject = Airplane.new(
        base_country_group: "United States",
        business_seats: 1,
        premium_economy_seats: 1,
        economy_seats: (Airplane::BUSINESS_SEAT_SIZE - Airplane::PREMIUM_ECONOMY_SEAT_SIZE) / Airplane::ECONOMY_SEAT_SIZE + 1,
        construction_date: Game.last.current_date - 1.day,
        end_of_useful_life: Game.last.current_date + 1.year,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        operator_id: nil,
        aircraft_model_id: AircraftModel.last.id,
      )

      expect(subject.save).to be false
      expect(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include "seats require more total floor space than available on airplane"
    end
  end

  context "set_configuration" do
    let(:family) { Fabricate(:aircraft_family) }
    let(:model) { Fabricate(:aircraft_model, family: family, floor_space: Airplane::ECONOMY_SEAT_SIZE * 100, takeoff_distance: 10000, speed: 1000, max_range: 13000) }

    it "updates the configuration, deducts cash from the airline, updates the flight costs, and adjusts the revenue on affected routes if the new configuration is valid" do
      initial_cash_on_hand = 1000000
      other_market = Fabricate(:market, name: "Washington")
      airline = Fabricate(:airline, cash_on_hand: initial_cash_on_hand)
      airline.base.airports.each{ |a| a.update!(exclusive_catchment: 1) }
      subject = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, base_country_group: airline.base.country_group, operator_id: airline.id, economy_seats: 50, business_seats: 0, premium_economy_seats: 0)
      game = Game.find(airline.game_id)
      bos = Fabricate(:airport, iata: "BOS", market: airline.base, runway: 10000, exclusive_catchment: 1)
      bos_gates = Gates.create!(airport: bos, game: game, current_gates: 5)
      Slot.create!(lessee_id: airline.id, gates: bos_gates)
      Population.create!(market_id: airline.base.id, year: 2000, population: 100)
      Tourists.create!(market_id: airline.base.id, year: 2000, volume: 10)
      lax = Fabricate(:airport, iata: "LAX", market: other_market, runway: 10000, exclusive_catchment: 1)
      lax_gates = Gates.create!(airport: lax, game: game, current_gates: 5)
      Slot.create!(lessee_id: airline.id, gates: lax_gates)
      airline_route = AirlineRoute.create!(airline: airline, origin_airport: bos, destination_airport: lax, economy_price: 1, business_price: 2, premium_economy_price: 2)
      AirplaneRoute.new(airplane: subject, route: airline_route, flight_cost: 1, frequencies: 1, block_time_mins: 1).save(validate: false)
      airplane_route = AirplaneRoute.last
      AirlineRouteRevenue.create!(airline_route: airline_route, revenue: 0, economy_pax: 0, business_pax: 0, premium_economy_pax: 0, exclusive_economy_revenue: 0, exclusive_business_revenue: 0, exclusive_premium_economy_revenue: 0)
      route_dollars = instance_double(RouteDollars, origin_market: airline.base, destination_market: other_market, origin_airport_iata: "BOS", destination_airport_iata: "LAX", date: Date.today, distance: 1000, business: 100, economy: 100, premium_economy: 100)
      expect(RouteDollars).to receive(:between_markets).with(airline.base, other_market, Date.today).and_return([route_dollars])
      subject.reload

      cost_to_reconfigure = subject.send(:cost_to_reconfigure, 1, 2, 3)
      expect(cost_to_reconfigure).to eq Airplane::RECONFIGURATION_COST_PER_SEAT_ECONOMY +
        Airplane::RECONFIGURATION_COST_PER_SEAT_PREMIUM_ECONOMY * 2 +
        Airplane::RECONFIGURATION_COST_PER_SEAT_BUSINESS * 3 +
        subject.send(:daily_profit)

      original_construction_date = subject.construction_date

      expect(subject.set_configuration(3, 2, 1)).to be true

      subject.reload
      airline.reload
      airline_route.reload
      airplane_route.reload

      assert_in_epsilon airline.cash_on_hand, initial_cash_on_hand - cost_to_reconfigure, 0.0000001
      expect(subject.economy_seats).to eq 1
      expect(subject.premium_economy_seats).to eq 2
      expect(subject.business_seats).to eq 3
      expect(subject.construction_date).to eq original_construction_date
      expect(airline_route.revenue.revenue).to be > 0
      expect(airplane_route.flight_cost).to be > 1
    end

    it "does not update the configuration, deduct cash from the airline, update the flight costs, or adjust the revenue on affected routes if the new configuration is equal to the old" do
      initial_cash_on_hand = 1000000
      airline = Fabricate(:airline, cash_on_hand: initial_cash_on_hand)
      subject = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, base_country_group: airline.base.country_group, operator_id: airline.id, economy_seats: 50, business_seats: 0, premium_economy_seats: 0)
      game = Game.find(airline.game_id)
      bos = Fabricate(:airport, iata: "BOS", market: airline.base, runway: 10000)
      bos_gates = Gates.create!(airport: bos, game: game, current_gates: 5)
      Slot.create!(lessee_id: airline.id, gates: bos_gates)
      Population.create!(market_id: airline.base.id, year: 2000, population: 100)
      Tourists.create!(market_id: airline.base.id, year: 2000, volume: 10)
      lax = Fabricate(:airport, iata: "LAX", market: airline.base, runway: 10000)
      lax_gates = Gates.create!(airport: lax, game: game, current_gates: 5)
      Slot.create!(lessee_id: airline.id, gates: lax_gates)
      airline_route = AirlineRoute.create!(airline: airline, origin_airport: bos, destination_airport: lax, economy_price: 1, business_price: 2, premium_economy_price: 2)
      AirplaneRoute.new(airplane: subject, route: airline_route, flight_cost: 1, frequencies: 1, block_time_mins: 1).save(validate: false)
      airplane_route = AirplaneRoute.last
      AirlineRouteRevenue.create!(airline_route: airline_route, revenue: 100, economy_pax: 50, business_pax: 0, premium_economy_pax: 0, exclusive_economy_revenue: 0, exclusive_business_revenue: 0, exclusive_premium_economy_revenue: 0)
      subject.reload

      original_construction_date = subject.construction_date

      expect(subject.set_configuration(0, 0, 50)).to be true

      subject.reload
      airline.reload
      airline_route.reload
      airplane_route.reload

      assert_in_epsilon airline.cash_on_hand, initial_cash_on_hand, 0.0000001
      expect(subject.economy_seats).to eq 50
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.business_seats).to eq 0
      expect(subject.construction_date).to eq original_construction_date
      expect(airline_route.revenue.revenue).to eq 100
      expect(airplane_route.flight_cost).to eq 1
    end

    it "updates the configuration and delivery date while deducting no money from the airline if the new configuration is valid but the airplane is unbuilt" do
      initial_cash_on_hand = 1000000
      airline = Fabricate(:airline, cash_on_hand: initial_cash_on_hand)
      game = Fabricate(:game)
      queue = Fabricate(:aircraft_manufacturing_queue, aircraft_family_id: family.id, game: game)
      subject = Fabricate(
        :airplane,
        aircraft_model: model,
        aircraft_family: family,
        base_country_group: airline.base.country_group,
        operator_id: airline.id,
        economy_seats: 50,
        business_seats: 0,
        premium_economy_seats: 0,
        aircraft_manufacturing_queue: queue,
        construction_date: game.current_date + 1.day,
      )
      subject.reload

      cost_to_reconfigure = subject.send(:cost_to_reconfigure, 48, 2, 3)
      expect(cost_to_reconfigure).to eq 0

      expect(subject.set_configuration(3, 2, 48)).to be true

      subject.reload
      airline.reload

      assert_in_epsilon airline.cash_on_hand, initial_cash_on_hand, 0.0000001
      expect(subject.economy_seats).to eq 48
      expect(subject.premium_economy_seats).to eq 2
      expect(subject.business_seats).to eq 3
      expect(subject.construction_date).to eq game.current_date + 2.days
    end

    it "does not update the configuration or deduct cash from the airline if the new configutation has too many seats" do
      initial_cash_on_hand = 1000000
      airline = Fabricate(:airline, cash_on_hand: initial_cash_on_hand)
      subject = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, base_country_group: airline.base.country_group, operator_id: airline.id, economy_seats: 10, premium_economy_seats: 10, business_seats: 10)

      expect(subject.set_configuration(3, 2, 100)).to be false
      subject.reload
      airline.reload

      expect(airline.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.economy_seats).to eq 10
      expect(subject.premium_economy_seats).to eq 10
      expect(subject.business_seats).to eq 10
      expect(subject.errors.full_messages).to include "Seats require more total floor space than available on airplane"
    end

    it "does not update the configutation or deduct cash from the airline if the airline does not have enough cash on hand" do
      initial_cash_on_hand = 100
      airline = Fabricate(:airline, cash_on_hand: initial_cash_on_hand)
      subject = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, base_country_group: airline.base.country_group, operator_id: airline.id, economy_seats: 10, premium_economy_seats: 10, business_seats: 10)

      expect(subject.set_configuration(3, 2, 1)).to be false
      subject.reload
      airline.reload

      expect(airline.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.economy_seats).to eq 10
      expect(subject.premium_economy_seats).to eq 10
      expect(subject.business_seats).to eq 10
      expect(subject.errors.full_messages).to include "Airline does not have enough cash on hand to reconfigure"
    end

    it "does not update the configutation or deduct cash from the airline if the airplane cannot fly all of its routes in the new configuration" do
      initial_cash_on_hand = 10000000
      airline = Fabricate(:airline, cash_on_hand: initial_cash_on_hand)
      subject = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, base_country_group: airline.base.country_group, operator_id: airline.id, economy_seats: 10, premium_economy_seats: 10, business_seats: 10)
      game = Game.find(airline.game_id)
      bos = Fabricate(:airport, iata: "BOS", market: airline.base, runway: 990)
      bos_gates = Gates.create!(airport: bos, game: game, current_gates: 5)
      Slot.create!(lessee_id: airline.id, gates: bos_gates)
      lax = Fabricate(:airport, iata: "LAX", market: airline.base, runway: 10000)
      lax_gates = Gates.create!(airport: lax, game: game, current_gates: 5)
      Slot.create!(lessee_id: airline.id, gates: lax_gates)
      Population.create!(market_id: airline.base.id, year: 2000, population: 100)
      Tourists.create!(market_id: airline.base.id, year: 2000, volume: 10)
      airline_route = AirlineRoute.create!(airline: airline, origin_airport: bos, destination_airport: lax, economy_price: 1, business_price: 2, premium_economy_price: 2)
      AirplaneRoute.new(airplane: subject, route: airline_route, flight_cost: 1, frequencies: 1, block_time_mins: 1).save(validate: false)
      airplane_route = AirplaneRoute.last
      AirlineRouteRevenue.create!(airline_route: airline_route, revenue: 2, economy_pax: 1, business_pax: 0, premium_economy_pax: 0, exclusive_economy_revenue: 0, exclusive_business_revenue: 0, exclusive_premium_economy_revenue: 0)
      subject.reload

      expect(subject.set_configuration(0, 0, 100)).to be false
      subject.reload

      expect(airline.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.economy_seats).to eq 10
      expect(subject.premium_economy_seats).to eq 10
      expect(subject.business_seats).to eq 10
      expect(subject.errors.full_messages).to include "Routes are not all able to be flown by the aircraft"
    end

    it "does not update the configutation or deduct cash from the airline if the airplane does not have enough block time to fly all of its routes in the new configuration" do
      initial_cash_on_hand = 10000000
      airline = Fabricate(:airline, cash_on_hand: initial_cash_on_hand)
      subject = Fabricate(:airplane, aircraft_model: model, aircraft_family: family, base_country_group: airline.base.country_group, operator_id: airline.id, economy_seats: 10, premium_economy_seats: 10, business_seats: 10)
      bos = Fabricate(:airport, iata: "BOS", market: airline.base, runway: 10000)
      lax = Fabricate(:airport, iata: "LAX", market: airline.base, runway: 10000)
      airline_route = AirlineRoute.create!(airline: airline, origin_airport: bos, destination_airport: lax, economy_price: 1, business_price: 2, premium_economy_price: 2)
      AirplaneRoute.new(airplane: subject, route: airline_route, flight_cost: 1, frequencies: 1000, block_time_mins: 1).save(validate: false)
      airplane_route = AirplaneRoute.last
      AirlineRouteRevenue.create!(airline_route: airline_route, revenue: 100, economy_pax: 50, business_pax: 0, premium_economy_pax: 0, exclusive_economy_revenue: 0, exclusive_business_revenue: 0, exclusive_premium_economy_revenue: 0)
      subject.reload

      expect(subject.set_configuration(0, 0, 100)).to be false

      subject.reload

      expect(airline.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.economy_seats).to eq 10
      expect(subject.premium_economy_seats).to eq 10
      expect(subject.business_seats).to eq 10
      expect(subject.errors.full_messages).to include "Airplane routes block time is too high"
    end
  end

  context "takeoff_distance" do
    it "is 1/2 the stated takeoff distance for a plane with no seats flying no distance taking off at sea level" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 0)

      expect(subject.takeoff_distance(0, 0)).to eq subject.aircraft_model.takeoff_distance / 2.0
    end

    it "is the maximum takeoff distance for a plane with the maximum seats and flying its maximum range taking off at sea level" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 10)

      assert_in_epsilon subject.takeoff_distance(0, subject.aircraft_model.max_range), subject.aircraft_model.takeoff_distance, 0.0000000001
    end

    it "increases at a higher elevation" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 10)

      expect(subject.takeoff_distance(1, subject.aircraft_model.max_range)).to be > subject.aircraft_model.takeoff_distance
    end

    it "decreases with fewer seats" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 9)

      expect(subject.takeoff_distance(0, subject.aircraft_model.max_range)).to be < subject.aircraft_model.takeoff_distance
      expect(subject.takeoff_distance(0, subject.aircraft_model.max_range)).to be > subject.aircraft_model.takeoff_distance / 2.0
    end

    it "decreases for a shorter flight" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 10)

      expect(subject.takeoff_distance(0, subject.aircraft_model.max_range - 1)).to be < subject.aircraft_model.takeoff_distance
      expect(subject.takeoff_distance(0, subject.aircraft_model.max_range - 1)).to be > subject.aircraft_model.takeoff_distance / 2.0
    end
  end

  context "turn_time_mins" do
    it "is minimal for an empty plane" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: 0)

      expect(subject.turn_time_mins).to eq Airplane::MIN_TURN_TIME_MINS
    end

    it "is increases as the seats on the plane increase" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)

      num_seats = (1..9).to_a.sample

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 10)
      subject.update(economy_seats: num_seats)

      old_turn_time = subject.turn_time_mins
      expect(subject.turn_time_mins).to be > Airplane::MIN_TURN_TIME_MINS

      subject.update(economy_seats: num_seats + 1)
      expect(subject.turn_time_mins).to be > old_turn_time
    end

    it "is calculated correctly" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, num_aisles: 1, family: family)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 100)
      subject.update(economy_seats: 20 / Airplane::TURN_TIME_MINS_PER_SEAT)

      expect(subject.turn_time_mins).to eq Airplane::MIN_TURN_TIME_MINS + 20
    end

    it "is lower for multi-aisle planes" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, num_aisles: 1, family: family)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)

      subject.aircraft_model.update(floor_space: Airplane::ECONOMY_SEAT_SIZE * 100)
      subject.update(economy_seats: (1..100).to_a.sample)

      single_aisle_turn_time = subject.turn_time_mins

      subject.aircraft_model.update(num_aisles: 2)

      expect(subject.turn_time_mins).to be < single_aisle_turn_time
    end
  end

  context "update_downstream_block_times" do
    it "updates AirplaneRoute block times" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 100, max_range: 100000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      gates_inu = Gates.create!(airport: inu, game: subject.game, current_gates: 100)
      Slot.create!(gates: gates_inu, lessee_id: Airline.last.id)
      gates_fun = Gates.create!(airport: fun, game: subject.game, current_gates: 100)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      airplane_route = AirplaneRoute.last

      subject.reload
      expect(subject.update(lease_rate: 100)).to be true
      airplane_route.reload
      expect(airplane_route.block_time_mins).to be < Airplane::MAX_TOTAL_BLOCK_TIME_MINS
    end

    it "is does not update AirplaneRoute block times if the change is invalid" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 100, max_range: 100000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)
      CabotageException.create!(country: inu.market.country)
      route_1_frequency = [1, 10000].sample
      route_2_frequency = [1, 10000].reject { |f| f == route_1_frequency }.first
      route_1 = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2 - 1,
        frequencies: route_1_frequency,
        flight_cost: 1,
        airplane: subject,
        route: route_1,
      ).save(validate: false)
      airplane_route_1 = AirplaneRoute.last
      route_2 = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: maj,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2 - 1,
        frequencies: route_2_frequency,
        flight_cost: 1,
        airplane: subject,
        route: route_2,
      ).save(validate: false)
      airplane_route_2 = AirplaneRoute.last

      subject.reload
      expect(subject.update(lease_rate: 100)).to be false
      airplane_route_1.reload
      airplane_route_2.reload
      expect(airplane_route_1.block_time_mins).to eq Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2 - 1
      expect(airplane_route_2.block_time_mins).to eq Airplane::MAX_TOTAL_BLOCK_TIME_MINS / 2 - 1
    end
  end

  context "utilization" do
    it "is calculated correctly" do
      family = Fabricate(:aircraft_family)
      model = Fabricate(:aircraft_model, floor_space: Airplane::ECONOMY_SEAT_SIZE, takeoff_distance: 100, max_range: 100000)
      subject = Fabricate(:airplane, aircraft_family: family, aircraft_model: model, operator_id: Airline.last.id, base_country_group: Airline.last.base.country_group)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      gates_inu = Gates.create!(airport: inu, game: subject.game, current_gates: 100)
      Slot.create!(gates: gates_inu, lessee_id: Airline.last.id)
      gates_fun = Gates.create!(airport: fun, game: subject.game, current_gates: 100)
      Slot.create!(gates: gates_fun, lessee_id: Airline.last.id)
      CabotageException.create!(country: inu.market.country)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        airline: Airline.last,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)
      airplane_route = AirplaneRoute.last

      subject.reload
      expect(subject.update(lease_rate: 100)).to be true
      subject.reload

      assert_in_epsilon subject.utilization, subject.round_trip_block_time(Calculation::Distance.between_airports(inu, fun)) / 420.0, 0.000001
    end
  end

  context "built?" do
    purchase_price_new = 100000000

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0, aircraft_family_id: family.id)
      model = AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000,
        max_range: 1200,
        speed: 500,
        fuel_burn: 1500,
        num_pilots: 2,
        num_flight_attendants: 3,
        price: purchase_price_new,
        takeoff_distance: 5000,
        useful_life: 30,
        family: family,
      )
      Airplane.create!(
        base_country_group: "United States",
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 1,
        construction_date: game.current_date - 1.day,
        end_of_useful_life: game.current_date + 1.year,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model_id: model.id,
      )
    end

    it "is false when the aircraft is not yet build" do
      subject = Airplane.last
      subject.update(construction_date: Date.tomorrow)
      subject.reload

      expect(subject.built?).to be false
    end

    it "is true when the aircraft has already been built" do
      subject = Airplane.last

      expect(subject.built?).to be true
    end
  end
end
