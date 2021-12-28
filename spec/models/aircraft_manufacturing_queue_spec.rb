require "rails_helper"

RSpec.describe AircraftManufacturingQueue do
  before(:each) do
    game = Game.create!(start_date: Date.yesterday, current_date: Date.today, end_date: Date.tomorrow + 10.years)
    family = AircraftFamily.create!(manufacturer: "Boeing", name: "737")
    AircraftManufacturingQueue.create!(game: game, production_rate: 0, aircraft_family_id: family.id)
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

  context "add_to_production_queue" do
    it "adds one plane when the existing queue is long and the production rate is low" do
      queue = AircraftManufacturingQueue.last
      queue.update!(production_rate: AircraftManufacturingQueue::LOW_PRODUCTION_RATES.min)
      queue.reload
      game = Game.last
      model = AircraftModel.last
      last_plane = Airplane.create!(
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 1,
        construction_date: game.current_date + (AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * 2 * AircraftManufacturingQueue::DAYS_PER_MONTH).days,
        end_of_useful_life: game.current_date + 10.years,
        aircraft_manufacturing_queue_id: queue.id,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )

      old_num_planes = Airplane.count

      queue.add_to_production_queue(model)

      plane = Airplane.last

      assert_in_delta (plane.construction_date - last_plane.construction_date).to_i, AircraftManufacturingQueue::DAYS_PER_MONTH / AircraftManufacturingQueue::LOW_PRODUCTION_RATES.min, 2
      expect(Airplane.count).to eq old_num_planes + 1
      expect(plane.aircraft_model_id).to eq model.id
    end

    it "adds one plane when the existing queue is long and the production rate is high" do
      queue = AircraftManufacturingQueue.last
      queue.update!(production_rate: 30)
      queue.reload
      game = Game.last
      model = AircraftModel.last
      last_plane = Airplane.create!(
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 1,
        construction_date: game.current_date + (AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * 2 * AircraftManufacturingQueue::DAYS_PER_MONTH).days,
        end_of_useful_life: game.current_date + 10.years,
        aircraft_manufacturing_queue_id: queue.id,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )

      old_num_planes = Airplane.count

      queue.add_to_production_queue(model)

      plane = Airplane.last

      assert_in_delta (plane.construction_date - last_plane.construction_date).to_i, 1, 1
      expect(Airplane.count).to eq old_num_planes + 1
      expect(plane.aircraft_model_id).to eq model.id
    end

    it "adds multiple planes when the existing queue is short" do
      queue = AircraftManufacturingQueue.last
      queue.update!(production_rate: 2)
      queue.reload
      game = Game.last
      model = AircraftModel.last
      last_plane = Airplane.create!(
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: 1,
        construction_date: game.current_date + 30.days,
        end_of_useful_life: game.current_date + 10.years,
        aircraft_manufacturing_queue_id: queue.id,
        operator_id: nil,
        aircraft_model: AircraftModel.last,
      )

      old_num_planes = Airplane.count

      queue.add_to_production_queue(model)

      plane = Airplane.last

      assert_in_delta (plane.construction_date - last_plane.construction_date).to_i, AircraftManufacturingQueue::QUEUE_LENGTH_MONTHS * AircraftManufacturingQueue::DAYS_PER_MONTH, 2
      expect(Airplane.count).to eq old_num_planes + 24
      expect(plane.aircraft_model_id).to eq model.id
    end
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
          end_of_useful_life: game.current_date + 10.years,
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

  context "optimize_production_rate" do
    context "increasing" do
      it "does not increase when the production rate is 0" do
        queue = AircraftManufacturingQueue.last
        game = queue.game
        Airplane.create!(
          business_seats: 0,
          premium_economy_seats: 0,
          economy_seats: 1,
          construction_date: game.current_date + 180.days,
          end_of_useful_life: game.current_date + 10.years,
          aircraft_manufacturing_queue_id: queue.id,
          operator_id: 1,
          aircraft_model: AircraftModel.last,
        )

        queue.optimize_production_rate
        queue.reload

        expect(queue.production_rate).to eq 0
      end

      it "increases within the low production rate scale" do
        queue = AircraftManufacturingQueue.last
        min_rate = AircraftManufacturingQueue::LOW_PRODUCTION_RATES.min
        queue.update!(production_rate: min_rate)
        game = queue.game
        Airplane.create!(
          business_seats: 0,
          premium_economy_seats: 0,
          economy_seats: 1,
          construction_date: game.current_date + 180.days,
          end_of_useful_life: game.current_date + 10.years,
          aircraft_manufacturing_queue_id: queue.id,
          operator_id: 1,
          aircraft_model: AircraftModel.last,
        )

        queue.optimize_production_rate
        queue.reload

        expect(queue.production_rate).to eq AircraftManufacturingQueue::LOW_PRODUCTION_RATES.select { |rate| rate > min_rate }.min
      end

      it "graduates from the low production rate scale when it reaches the top" do
        queue = AircraftManufacturingQueue.last
        max_rate = AircraftManufacturingQueue::LOW_PRODUCTION_RATES.max
        queue.update!(production_rate: max_rate)
        game = queue.game
        Airplane.create!(
          business_seats: 0,
          premium_economy_seats: 0,
          economy_seats: 1,
          construction_date: game.current_date + 180.days,
          end_of_useful_life: game.current_date + 10.years,
          aircraft_manufacturing_queue_id: queue.id,
          operator_id: 1,
          aircraft_model: AircraftModel.last,
        )

        queue.optimize_production_rate
        queue.reload

        expect(queue.production_rate).to eq max_rate + AircraftManufacturingQueue::PRODUCTION_RATE_CHANGE_INTERVAL
      end

      it "increases by the production rate interval when not on the low production rate scale" do
        queue = AircraftManufacturingQueue.last
        initial_rate = 345.432745
        queue.update!(production_rate: initial_rate)
        game = queue.game
        Airplane.create!(
          business_seats: 0,
          premium_economy_seats: 0,
          economy_seats: 1,
          construction_date: game.current_date + 180.days,
          end_of_useful_life: game.current_date + 10.years,
          aircraft_manufacturing_queue_id: queue.id,
          operator_id: 1,
          aircraft_model: AircraftModel.last,
        )

        queue.optimize_production_rate
        queue.reload

        expect(queue.production_rate).to eq initial_rate + AircraftManufacturingQueue::PRODUCTION_RATE_CHANGE_INTERVAL
      end
    end

    context "decreasing" do
      it "decreases by the production rate interval when not on the low production rate scale" do
        queue = AircraftManufacturingQueue.last
        initial_rate = 345.432745
        queue.update!(production_rate: initial_rate)
        game = queue.game
        Airplane.create!(
          business_seats: 0,
          premium_economy_seats: 0,
          economy_seats: 1,
          construction_date: game.current_date + 180.days,
          end_of_useful_life: game.current_date + 10.years,
          aircraft_manufacturing_queue_id: queue.id,
          operator_id: nil,
          aircraft_model: AircraftModel.last,
        )

        queue.optimize_production_rate
        queue.reload

        expect(queue.production_rate).to eq initial_rate - AircraftManufacturingQueue::PRODUCTION_RATE_CHANGE_INTERVAL
      end

      it "uses the low production rate scale when at the threshold for it" do
        queue = AircraftManufacturingQueue.last
        initial_rate = AircraftManufacturingQueue::LOW_PRODUCTION_RATES.max + AircraftManufacturingQueue::PRODUCTION_RATE_CHANGE_INTERVAL / 10.0
        queue.update!(production_rate: initial_rate)
        game = queue.game
        Airplane.create!(
          business_seats: 0,
          premium_economy_seats: 0,
          economy_seats: 1,
          construction_date: game.current_date + 180.days,
          end_of_useful_life: game.current_date + 10.years,
          aircraft_manufacturing_queue_id: queue.id,
          operator_id: nil,
          aircraft_model: AircraftModel.last,
        )

        queue.optimize_production_rate
        queue.reload

        expect(queue.production_rate).to eq AircraftManufacturingQueue::LOW_PRODUCTION_RATES.max
      end

      it "decreases within the low production rate scale" do
        queue = AircraftManufacturingQueue.last
        initial_rate = AircraftManufacturingQueue::LOW_PRODUCTION_RATES.max
        queue.update!(production_rate: initial_rate)
        game = queue.game
        Airplane.create!(
          business_seats: 0,
          premium_economy_seats: 0,
          economy_seats: 1,
          construction_date: game.current_date + 180.days,
          end_of_useful_life: game.current_date + 10.years,
          aircraft_manufacturing_queue_id: queue.id,
          operator_id: nil,
          aircraft_model: AircraftModel.last,
        )

        queue.optimize_production_rate
        queue.reload

        expect(queue.production_rate).to eq AircraftManufacturingQueue::LOW_PRODUCTION_RATES.select { |rate| rate < initial_rate }.max
      end

      it "stops production when reducing from the minimum production rate" do
        queue = AircraftManufacturingQueue.last
        initial_rate = AircraftManufacturingQueue::LOW_PRODUCTION_RATES.min
        queue.update!(production_rate: initial_rate)
        game = queue.game
        Airplane.create!(
          business_seats: 0,
          premium_economy_seats: 0,
          economy_seats: 1,
          construction_date: game.current_date + 180.days,
          end_of_useful_life: game.current_date + 10.years,
          aircraft_manufacturing_queue_id: queue.id,
          operator_id: nil,
          aircraft_model: AircraftModel.last,
        )

        queue.optimize_production_rate
        queue.reload

        expect(queue.production_rate).to eq 0
      end
    end
  end
end
