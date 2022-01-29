require "rails_helper"

RSpec.describe AircraftModel do
  subject = AircraftModel.new(speed: 108)

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
end
