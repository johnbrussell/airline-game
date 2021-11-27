require "rails_helper"

RSpec.describe AircraftManufacturingQueue do
  before(:each) do
    game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
    AircraftManufacturingQueue.create!(game: game, production_rate: 0)
    family = AircraftFamily.create!(manufacturer: "Boeing", name: "737")
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
      useful_life: 30,
      family: family,
    )
  end

  context "start_production" do
    context "start_family_production" do
      it "creates a production queue of length QUEUE_LENGTH_MONTHS starting PRODUCTION_START_ADVANCE_NOTICE_MONTHS in the future" do
        model = AircraftModel.last
        queue = AircraftManufacturingQueue.last
        game = Game.last

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

    context "start_model_production" do
      it "adds aircraft to queue up to QUEUE_LENGTH_MONTHS in the future" do
        model_1 = AircraftModel.last
        model_2 = AircraftModel.create!(
          name: "737-200",
          production_start_year: 1979,
          floor_space: 1000,
          max_range: 1200,
          speed: 500,
          fuel_burn: 1500,
          num_pilots: 2,
          num_flight_attendants: 3,
          price: 10000000,
          takeoff_distance: 5000,
          useful_life: 30,
          family: model_1.family,
        )
        queue = AircraftManufacturingQueue.last
        game = Game.last

        old_aircraft = Airplane.count

        queue.start_production(model_1)
        queue.update!(production_rate: 1)

        expected_aircraft_1 = old_aircraft + AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * AircraftManufacturingQueue::START_PRODUCTION_RATE
        actual_aircraft_1 = Airplane.count

        expect(actual_aircraft_1).to eq expected_aircraft_1

        queue.start_production(model_2)

        expected_aircraft_2 = expected_aircraft_1 + [0, (AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS - 1 - AircraftManufacturingQueue::PRODUCTION_START_ADVANCE_NOTICE_MONTHS)].max + 1
        actual_aircraft_2 = Airplane.count

        expect(actual_aircraft_2).to eq expected_aircraft_2

        last_airplane = Airplane.last

        assert_in_delta(
          Airplane.last.construction_date,
          game.current_date +
            (AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * 30.5).round().days +
            (AircraftManufacturingQueue::PRODUCTION_START_ADVANCE_NOTICE_MONTHS * 30.5).round().days,
          (0.1 * (AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * 30.5)).round().days
        )

        last_airplane_in_queue = Airplane.all.max_by(&:construction_date)

        expect(last_airplane_in_queue.aircraft_model_id).to eq model_1.id
      end
    end
  end
end
