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
end
