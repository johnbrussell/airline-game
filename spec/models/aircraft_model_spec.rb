require "rails_helper"

RSpec.describe AircraftModel do
  subject = AircraftModel.new(speed: 100)

  context "flight_time_mins" do
    it "is correct for zero distance flights" do
      expect(subject.flight_time_mins(0)).to eq 2 * AircraftModel::MIN_TAXI_TIME_MINS
    end

    it "is correct for very short flights" do
      expect(subject.flight_time_mins(5)).to eq 12
    end

    it "is correct for short flights" do
      expect(subject.flight_time_mins(subject.speed * AircraftModel::SLOW_SPEED * AircraftModel::SLOW_DISTANCE_TIME_MINS / 60.0)).to eq AircraftModel::SLOW_DISTANCE_TIME_MINS + 2 * AircraftModel::MIN_TAXI_TIME_MINS
      expect(subject.flight_time_mins(25)).to eq 36
    end

    it "is correct for longer flights" do
      expect(subject.flight_time_mins(125)).to eq 96
    end
  end
end
