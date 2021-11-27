require "rails_helper"

RSpec.describe AircraftManufacturingQueue do
  context "start_production" do
    it "creates a production queue of length QUEUE_LENGTH_MONTHS starting PRODUCTION_START_ADVANCE_NOTICE_MONTHS in the future" do
      game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
      queue = AircraftManufacturingQueue.create!(game: game)
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
        price: 10000000,
        takeoff_distance: 5000,
        useful_life: 30,
        family: family,
      )

      old_aircraft = Airplane.count

      queue.start_production(model)

      expected_aircraft = old_aircraft + AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * AircraftManufacturingQueue::START_PRODUCTION_RATE
      actual_aircraft = Airplane.count

      expect(actual_aircraft).to eq expected_aircraft

      last_airplane = Airplane.last

      assert_in_delta(
        Airplane.last.construction_date,
        game.current_date +
          (AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * 30.5).round().days +
          (AircraftManufacturingQueue::PRODUCTION_START_ADVANCE_NOTICE_MONTHS * 30.5).round().days,
        (0.1 * ((AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS + AircraftManufacturingQueue::PRODUCTION_START_ADVANCE_NOTICE_MONTHS) * 30.5)).round().days
      )
    end
  end
end
