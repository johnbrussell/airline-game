require "rails_helper"

RSpec.describe Airplane do
  context "has_operator?" do
    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      AircraftManufacturingQueue.create!(game: game)
      family = AircraftFamily.create!(
        name: "737",
        manufacturer: "Boeing",
      )
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
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        aircraft_model: AircraftModel.last,
      )

      expect(subject.has_operator?).to be true
    end

    it "is false when the airplane is not owned" do
      subject = Airplane.create!(
        operator_id: nil,
        construction_date: Date.today,
        aircraft_manufacturing_queue: AircraftManufacturingQueue.last,
        aircraft_model: AircraftModel.last,
      )

      expect(subject.has_operator?).to be false
    end
  end

  context "purchase_price" do
    purchase_price_new = 100000000

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737")
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

  context "lease_rate_per_day" do
    purchase_price_new = 100000000

    before(:each) do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      queue = AircraftManufacturingQueue.create!(game: game, production_rate: 0)
      family = AircraftFamily.create!(manufacturer: "Boeing", name: "737")
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
end
