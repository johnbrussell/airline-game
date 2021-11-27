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

        expected_aircraft = old_aircraft + AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * AircraftManufacturingQueue::START_PRODUCTION_RATE + 1
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

        expect(queue.reload.production_rate).to eq AircraftManufacturingQueue::START_PRODUCTION_RATE
      end
    end

    context "start_model_production" do
      it "adds aircraft to queue up to the maximum aircraft construction date in the future" do
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
        queue.update!(production_rate: AircraftManufacturingQueue::START_PRODUCTION_RATE * 2.0)
        game.update!(current_date: game.current_date + 10.days)

        expected_aircraft_1 = old_aircraft + AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * AircraftManufacturingQueue::START_PRODUCTION_RATE + 1
        actual_aircraft_1 = Airplane.count
        Airplane.last.update!(construction_date: Airplane.all.max_by(&:construction_date).construction_date)

        expect(actual_aircraft_1).to eq expected_aircraft_1

        queue.start_production(model_2)

        expected_aircraft_2 = expected_aircraft_1 + AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS + 1
        actual_aircraft_2 = Airplane.count

        expect(actual_aircraft_2).to eq expected_aircraft_2

        last_airplane = Airplane.last

        assert_in_delta(
          Airplane.last.construction_date,
          game.current_date +
            (AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * AircraftManufacturingQueue::DAYS_PER_MONTH).round().days +
            (AircraftManufacturingQueue::PRODUCTION_START_ADVANCE_NOTICE_MONTHS * AircraftManufacturingQueue::DAYS_PER_MONTH).round().days +
            30.days,
          (0.1 * (AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * AircraftManufacturingQueue::DAYS_PER_MONTH)).round().days
        )

        last_airplane_in_queue = Airplane.all.max_by(&:construction_date)

        expect(last_airplane_in_queue.aircraft_model_id).to eq model_1.id
        expect(queue.reload.production_rate).to eq AircraftManufacturingQueue::START_PRODUCTION_RATE * 2.0
      end

      it "adds aircraft to queue up to QUEUE_LENGTH_MONTHS in the future if the outstanding queue is short" do
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

        Airplane.create!(
          aircraft_model_id: model_1.id,
          business_seats: 0,
          premium_economy_seats: 0,
          economy_seats: 1,
          construction_date: game.current_date + AircraftManufacturingQueue::PRODUCTION_START_ADVANCE_NOTICE_MONTHS * AircraftManufacturingQueue::DAYS_PER_MONTH + 1.day,
          aircraft_manufacturing_queue_id: queue.id,
        )
        queue.update!(production_rate: AircraftManufacturingQueue::START_PRODUCTION_RATE / 2.0)

        queue.start_production(model_2)

        expected_aircraft_2 = 1 + [0, (AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS - AircraftManufacturingQueue::PRODUCTION_START_ADVANCE_NOTICE_MONTHS - 1)].max + 2
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

        expect(last_airplane_in_queue.aircraft_model_id).to eq model_2.id
        expect(queue.reload.production_rate).to eq AircraftManufacturingQueue::START_PRODUCTION_RATE

        expect(queue.airplanes.select { |airplane| airplane.aircraft_model_id == model_2.id }.count).to eq \
          AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS - AircraftManufacturingQueue::PRODUCTION_START_ADVANCE_NOTICE_MONTHS + 1
      end
    end
  end
end
