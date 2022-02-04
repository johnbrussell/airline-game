require "rails_helper"

RSpec.describe Airplane do
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
      game = Game.first
      other_game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      other_queue = AircraftManufacturingQueue.create!(game: other_game, aircraft_family_id: 1, production_rate: 1)

      valid_airplane = Airplane.create!(
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.first,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.first,
        operator_id: 1,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        construction_date: game.current_date,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.first,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
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
      game = Game.first
      other_game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      other_queue = AircraftManufacturingQueue.create!(game: other_game, aircraft_family_id: 1, production_rate: 1)

      valid_airplane = Airplane.create!(
        construction_date: game.current_date,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.first,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        construction_date: game.current_date,
        end_of_useful_life: game.current_date + useful_life_years.years,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.first,
        operator_id: 1,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + useful_life_years.years + 1.day,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.first,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
        construction_date: game.current_date - useful_life_years.years - 1.day,
        end_of_useful_life: game.current_date - 1.day,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.first,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )
      Airplane.create!(
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
      Airplane.create!(aircraft_model_id: model.id, aircraft_manufacturing_queue_id: queue.id, operator_id: 2, construction_date: Date.tomorrow, end_of_useful_life: Date.tomorrow + 2.days)
    end

    it "only includes planes with the specified operator" do
      model = AircraftModel.last
      queue = AircraftManufacturingQueue.last
      airplane = Airplane.create!(aircraft_model_id: model.id, aircraft_manufacturing_queue_id: queue.id, operator_id: 1, construction_date: Date.tomorrow, end_of_useful_life: Date.tomorrow + 2.days)
      expected = [airplane]

      actual = Airplane.with_operator(1)

      expect(actual).to eq expected
    end

    it "works for nil" do
      model = AircraftModel.last
      queue = AircraftManufacturingQueue.last
      airplane = Airplane.create!(aircraft_model_id: model.id, aircraft_manufacturing_queue_id: queue.id, operator_id: nil, construction_date: Date.tomorrow, end_of_useful_life: Date.tomorrow + 2.days)
      expected = [airplane]

      actual = Airplane.with_operator(nil)

      expect(actual).to eq expected
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
      subject = Fabricate(:airplane, aircraft_family: family)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )

      subject.reload
      expect(subject.valid?).to be true
    end

    it "is false when the routes' block time is too much" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.new(
        block_time_mins: Airplane::MAX_TOTAL_BLOCK_TIME_MINS + 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      ).save(validate: false)

      subject.reload
      expect(subject.valid?).to be false
      expect(subject.errors.full_messages).to include "Airplane routes block time is too high"
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
      subject = Airplane.create!(
        operator_id: 1,
        construction_date: Date.today,
        end_of_useful_life: Date.tomorrow,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        aircraft_model: AircraftModel.last,
      )

      expect(subject.has_operator?).to be true
    end

    it "is false when the airplane is not owned" do
      subject = Airplane.create!(
        operator_id: nil,
        construction_date: Date.today,
        end_of_useful_life: Date.tomorrow,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        aircraft_model: AircraftModel.last,
      )

      expect(subject.has_operator?).to be false
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
      subject = Airplane.last
      expect(subject.update(operator_id: 1)).to be true
    end

    it "is true when selling an airplane" do
      subject = Airplane.last
      subject.update(operator_id: 1)

      expect(subject.update(operator_id: nil)).to be true
    end

    it "is true when updating an unowned airplane" do
      subject = Airplane.last
      expect(subject.update(economy_seats: 2)).to be true
    end

    it "is true when updating an owned airplane" do
      subject = Airplane.last
      subject.update(operator_id: 1)

      expect(subject.update(economy_seats: 2)).to be true
    end

    it "is false when selling an airplane from one airline to another" do
      subject = Airplane.last
      subject.update(operator_id: 1)

      expect(subject.update(operator_id: 2)).to be false
      expect(subject.errors.map{ |error| "#{error.attribute} #{error.message}" }).to include "operator_id cannot be changed from one airline directly to another; must be put on the market first"
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

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0, aircraft_family_id: family.id)
      model = AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000000,
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
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 0,
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + 1.year,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model_id: model.id,
      )
      Airline.create!(cash_on_hand: purchase_price_new * 2, name: "J Air", base_id: 1, game_id: game.id)
    end

    it "returns false if the airline does not have enough money" do
      subject = Airplane.last
      buyer = Airline.last

      buyer.update(cash_on_hand: 100)
      buyer.reload

      expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq 100
      expect(subject.operator_id).to be nil
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
      expect(subject.lease_expiry).to be nil
    end

    it "returns false if the plane is already owned by the buyer" do
      subject = Airplane.last
      buyer = Airline.last

      subject.update(operator_id: buyer.id)
      subject.reload

      initial_cash_on_hand = buyer.cash_on_hand

      expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.operator_id).to be buyer.id
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
      expect(subject.lease_expiry).to be nil
    end

    it "returns false if the plane is already owned by another airline" do
      subject = Airplane.last
      buyer = Airline.last

      subject.update(operator_id: buyer.id + 1)
      subject.reload

      initial_cash_on_hand = buyer.cash_on_hand

      expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq initial_cash_on_hand
      expect(subject.operator_id).to be buyer.id + 1
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
      expect(subject.lease_expiry).to be nil
    end

    context "new plane" do
      it "returns true, assigns the plane to the airline, and installs the right number of seats" do
        subject = Airplane.last
        buyer = Airline.last
        game = Game.last

        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be true

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to eq initial_cash_on_hand
        expect(subject.operator_id).to eq buyer.id
        expect(subject.business_seats).to eq 3
        expect(subject.premium_economy_seats).to eq 4
        expect(subject.economy_seats).to eq 5
        expect(subject.lease_expiry).to eq subject.construction_date + 100.days
        expect(subject.lease_rate).to be > 0
      end

      it "returns false if the number of seats requested requires too much square footage" do
        subject = Airplane.last
        buyer = Airline.last

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
        expect(subject.business_seats).to eq 0
        expect(subject.premium_economy_seats).to eq 0
        expect(subject.economy_seats).to eq 0
        expect(subject.lease_expiry).to be nil
      end
    end

    context "used plane" do
      it "does not update the seating configuration" do
        subject = Airplane.last
        buyer = Airline.last
        game = Game.last

        subject.update(construction_date: game.current_date)
        subject.reload
        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.lease(airline = buyer, length_in_days = 100, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be true

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to be < initial_cash_on_hand
        expect(subject.operator_id).to eq buyer.id
        expect(subject.business_seats).to eq 0
        expect(subject.premium_economy_seats).to eq 0
        expect(subject.economy_seats).to eq 0
        expect(subject.lease_expiry).to eq game.current_date + 100.days
        expect(subject.lease_rate).to be > 0
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

  context "purchase" do
    purchase_price_new = 100000000

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737", country_group: "United States")
      queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0, aircraft_family_id: family.id)
      model = AircraftModel.create!(
        name: "737-100",
        production_start_year: 1969,
        floor_space: 1000000,
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
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 0,
        construction_date: game.current_date + 1.day,
        end_of_useful_life: game.current_date + 1.year,
        aircraft_manufacturing_queue: queue,
        operator_id: nil,
        aircraft_model_id: model.id,
      )
      Airline.create!(cash_on_hand: purchase_price_new * 2, name: "J Air", base_id: 1, game_id: game.id)
    end

    it "returns false if the airline does not have enough money" do
      subject = Airplane.last
      buyer = Airline.last

      buyer.update(cash_on_hand: 100)
      buyer.reload

      expect(subject.purchase(airline = buyer, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be false

      subject.reload
      buyer.reload

      expect(buyer.cash_on_hand).to eq 100
      expect(subject.operator_id).to be nil
      expect(subject.business_seats).to eq 0
      expect(subject.premium_economy_seats).to eq 0
      expect(subject.economy_seats).to eq 0
    end

    it "returns false if the plane is already owned by the buyer" do
      subject = Airplane.last
      buyer = Airline.last

      subject.update(operator_id: buyer.id)
      subject.reload

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
      subject = Airplane.last
      buyer = Airline.last

      subject.update(operator_id: buyer.id + 1)
      subject.reload

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
        subject = Airplane.last
        buyer = Airline.last

        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.purchase(airline = buyer, business_seats = 3, premium_economy_seats = 4, economy_seats = 5)).to be true

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to eq initial_cash_on_hand - purchase_price_new / 2
        expect(subject.operator_id).to eq buyer.id
        expect(subject.business_seats).to eq 3
        expect(subject.premium_economy_seats).to eq 4
        expect(subject.economy_seats).to eq 5
      end

      it "returns false if the number of seats requested requires too much square footage" do
        subject = Airplane.last
        buyer = Airline.last

        initial_cash_on_hand = buyer.cash_on_hand

        expect(subject.purchase(airline = buyer, business_seats = 1, premium_economy_seats = 1, economy_seats = subject.aircraft_model.floor_space / Airplane::ECONOMY_SEAT_SIZE + 1)).to be false

        subject.reload
        buyer.reload

        expect(buyer.cash_on_hand).to eq initial_cash_on_hand
        expect(subject.operator_id).to be nil
        expect(subject.business_seats).to eq 0
        expect(subject.premium_economy_seats).to eq 0
        expect(subject.economy_seats).to eq 0
      end
    end

    context "used" do
      it "does not update the seating configuration" do
        subject = Airplane.last
        buyer = Airline.last
        game = Game.last

        subject.update(construction_date: game.current_date)
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
      end
    end
  end

  context "range_from_airport" do
    context "num_seats" do
      it "is equal to the number of seats on the airplane" do
        family = Fabricate(:aircraft_family)
        subject = Fabricate(:airplane, aircraft_family: family)

        subject.update(economy_seats: 10, business_seats: 20, premium_economy_seats: 30)

        expect(subject.send(:num_seats)).to eq 60
      end
    end

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
      subject = Fabricate(:airplane, aircraft_family: family)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )

      expect(subject.routes_connected_with?("INU", "LGA")).to be true
      expect(subject.routes_connected_with?("FUN", "LGA")).to be true
      expect(subject.routes_connected_with?("JFK", "FUN")).to be true
      expect(subject.routes_connected_with?("JFK", "INU")).to be true
    end

    it "is false if the origin and destination provided do not connect to the airplane's existing routes" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )
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
      subject = Fabricate(:airplane, aircraft_family: family)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )
      subject.reload

      expect(subject.routes_connected_without?("LGA", "JFK")).to be true
    end

    it "is true if the airplane's only route is the origin and destination supplied" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )
      subject.reload

      expect(subject.routes_connected_without?("INU", "FUN")).to be true
      expect(subject.routes_connected_without?("FUN", "INU")).to be true
    end

    it "is true if the airplane's only routes are the origin and destination supplied and another connected route" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: trw,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )
      subject.reload

      expect(subject.routes_connected_without?("INU", "FUN")).to be true
      expect(subject.routes_connected_without?("FUN", "INU")).to be true
      expect(subject.routes_connected_without?("FUN", "TRW")).to be true
      expect(subject.routes_connected_without?("TRW", "FUN")).to be true
    end

    it "is false if the origin and destination supplied are a necessary link between the airplane's routes" do
      family = Fabricate(:aircraft_family)
      subject = Fabricate(:airplane, aircraft_family: family)
      inu = Fabricate(:airport, iata: "INU")
      fun = Fabricate(:airport, iata: "FUN", market: inu.market)
      trw = Fabricate(:airport, iata: "TRW", market: inu.market)
      maj = Fabricate(:airport, iata: "MAJ", market: inu.market)
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: inu,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: fun,
        destination_airport: trw,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )
      route = AirlineRoute.create!(
        economy_price: 1,
        business_price: 2,
        premium_economy_price: 1.5,
        origin_airport: inu,
        destination_airport: maj,
        distance: 1,
      )
      AirplaneRoute.create!(
        block_time_mins: 1,
        frequencies: 1,
        flight_cost: 1,
        airplane: subject,
        route: route,
      )
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
