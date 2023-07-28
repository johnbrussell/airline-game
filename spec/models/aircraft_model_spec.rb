require "rails_helper"

RSpec.describe AircraftModel do
  subject = AircraftModel.new(speed: 108, fuel_burn: 1000)

  context "flight_time_mins" do
    it "is correct for zero distance flights" do
      expect(subject.flight_time_mins(0)).to eq 2 * AircraftModel::MIN_TAXI_TIME_MINS
    end

    it "is correct for very short flights" do
      expect(subject.flight_time_mins(3)).to eq 11
    end

    it "is correct for short flights" do
      expect(
        subject.flight_time_mins(
          subject.speed * AircraftModel::SLOW_SPEED_MULTIPLE * AircraftModel::SLOW_DISTANCE_TIME_MINS / 60.0 +
            subject.speed * AircraftModel::VERY_SLOW_SPEED_MULTIPLE * AircraftModel::VERY_SLOW_DISTANCE_TIME_MINS / 60.0
        )
      ).to eq AircraftModel::VERY_SLOW_DISTANCE_TIME_MINS + AircraftModel::SLOW_DISTANCE_TIME_MINS + 2 * AircraftModel::MIN_TAXI_TIME_MINS
      expect(subject.flight_time_mins(24)).to eq 36
    end

    it "is correct for longer flights" do
      expect(subject.flight_time_mins(60)).to eq 61
    end
  end

  context "flight_fuel_burn" do
    it "is just the taxi fuel for flights of zero distance" do
      expect(subject.flight_fuel_burn(0)).to eq 2 * AircraftModel::MIN_TAXI_TIME_MINS * subject.fuel_burn / 60.0
    end

    it "is roughly the hourly fuel burn for a one hour flight" do
      approximate_one_hour_fuel_burn = 2 * AircraftModel::MIN_TAXI_TIME_MINS * subject.fuel_burn / 60.0 + subject.fuel_burn

      expect(subject.flight_fuel_burn(69)).to be > approximate_one_hour_fuel_burn
      assert_in_epsilon subject.flight_fuel_burn(69), approximate_one_hour_fuel_burn, 0.0151
    end

    it "eventually grows faster than the distance but not at first" do
      one_hour_fuel_burn = subject.flight_fuel_burn(69)
      expect(subject.flight_fuel_burn(70)).to be > one_hour_fuel_burn
      expect(subject.flight_fuel_burn(1) / subject.flight_time_mins(1)).to be > subject.flight_fuel_burn(0) / subject.flight_time_mins(0)
      expect(subject.flight_fuel_burn(70) / subject.flight_time_mins(70)).to be > one_hour_fuel_burn / subject.flight_time_mins(69)
      expect(subject.flight_fuel_burn(70) / 70).to be < one_hour_fuel_burn / 69
      expect(subject.flight_fuel_burn(7000) / 7000).to be > subject.flight_fuel_burn(6999) / 6999
    end
  end

  context "lease_premium" do
    it "is greater than one" do
      subject.update(useful_life: 100, price: 1000000)

      expect(subject.lease_premium).to be > 1
    end

    it "decreases as aircraft useful life increases" do
      subject.update(useful_life: 100, price: 1000000)
      subject_2 = AircraftModel.new(useful_life: 101, price: subject.price)

      expect(subject.lease_premium).to be > subject_2.lease_premium
    end
  end

  context "maintenance_cost_per_day" do
    it "is calculated correctly" do
      subject = Fabricate(:aircraft_model, useful_life: 100, price: 3652400)

      expect(subject.maintenance_cost_per_day(0)).to eq 300
      expect(subject.maintenance_cost_per_day(36524)).to eq 1200
    end
  end

  context "value_at_age" do
    it "decreases with aircraft age but always remains positive" do
      subject.update(useful_life: 100, price: 1000000)

      [1, 10, 1000, 10000, 50000].each do |age|
        expect(subject.value_at_age(age)).to be > subject.value_at_age(age + 1)
        expect(subject.value_at_age(age)).to be > 0
      end
    end

    it "is greater at the same age for aircraft models with a greater useful life" do
      subject.update(useful_life: 100, price: 1000000)
      subject_2 = AircraftModel.new(useful_life: subject.useful_life - 1, price: subject.price)

      age = 1000

      expect(subject.value_at_age(age)).to be > subject_2.value_at_age(age)
    end

    it "is PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE of the price when at the end of its useful life" do
      price = 1000000
      useful_life_years = 30
      useful_life_days = useful_life_years * AircraftModel::DAYS_PER_YEAR
      subject.update(useful_life: useful_life_years, price: price)

      assert_in_epsilon subject.value_at_age(useful_life_days), price * AircraftModel::PERCENT_VALUE_MAINTAINED_AT_END_OF_USEFUL_LIFE, 0.000000001
    end
  end
end
