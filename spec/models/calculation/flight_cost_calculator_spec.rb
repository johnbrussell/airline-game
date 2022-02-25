require "rails_helper"

RSpec.describe Calculation::FlightCostCalculator do
  num_fas = (0..6).to_a.sample
  num_pilots = (1..3).to_a.sample
  airplane_attributes = {
    base_country_group: "New Zealand",
    business_seats: (0..4).to_a.sample,
    construction_date: Date.today,
    economy_seats: (1..138).to_a.sample,
    end_of_useful_life: Date.today + 1.day,
    premium_economy_seats: (1..12).to_a.sample,
  }
  aircraft_model_attributes = {
    name: "foo",
    production_start_year: Date.today.year,
    floor_space: 4 * Airplane::BUSINESS_SEAT_SIZE + 12 * Airplane::PREMIUM_ECONOMY_SEAT_SIZE + 138 * Airplane::ECONOMY_SEAT_SIZE,
    max_range: 1000,
    fuel_burn: 1500,
    speed: 556,
    num_aisles: [1, 2].sample,
    num_pilots: num_pilots,
    num_flight_attendants: num_fas,
    price: 1,
    takeoff_distance: 1,
    useful_life: 1,
  }

  airplane = Airplane.new(
    aircraft_model: AircraftModel.new(
      **aircraft_model_attributes,
    ),
    **airplane_attributes,
  )

  context "cost" do
    it "is greater than zero and increases with distance" do
      zero_distance_cost = Calculation::FlightCostCalculator.new(airplane, 0).cost
      expect(zero_distance_cost).to be > 0

      one_distance_cost = Calculation::FlightCostCalculator.new(airplane, 1).cost
      expect(one_distance_cost).to be > zero_distance_cost

      one_thousand_distance_cost = Calculation::FlightCostCalculator.new(airplane, 1000).cost
      expect(one_thousand_distance_cost).to be > one_distance_cost
    end
  end

  context "pilots" do
    it "scales linearly with flight time" do
      mock_model = instance_double(
        AircraftModel,
        **aircraft_model_attributes,
      )
      mock_airplane = instance_double(
        Airplane,
        aircraft_model: mock_model,
        **airplane_attributes,
      )

      distance = 100

      expect(mock_model).to receive(:flight_time_mins).with(distance).and_return(60)
      expect(Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:pilots)).to eq Calculation::FlightCostCalculator::PILOT_HOURLY_COST * num_pilots

      expect(mock_model).to receive(:flight_time_mins).with(distance).and_return(90)
      expect(Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:pilots)).to eq Calculation::FlightCostCalculator::PILOT_HOURLY_COST * num_pilots * 1.5
    end
  end

  context "flight_attendants" do
    it "scales linearly with flight time" do
      mock_model = instance_double(
        AircraftModel,
        **aircraft_model_attributes,
      )
      mock_airplane = instance_double(
        Airplane,
        aircraft_model: mock_model,
        **airplane_attributes,
      )

      distance = 100

      expect(mock_model).to receive(:flight_time_mins).with(distance).and_return(60)
      expect(Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:flight_attendants)).to eq Calculation::FlightCostCalculator::FA_HOURLY_COST * num_fas

      expect(mock_model).to receive(:flight_time_mins).with(distance).and_return(90)
      expect(Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:flight_attendants)).to eq Calculation::FlightCostCalculator::FA_HOURLY_COST * num_fas * 1.5
    end
  end

  context "fuel" do
    it "calculates correctly" do
      mock_model = instance_double(
        AircraftModel,
        **aircraft_model_attributes,
      )
      mock_airplane = instance_double(
        Airplane,
        aircraft_model: mock_model,
        **airplane_attributes,
      )

      distance = 100

      expect(mock_model).to receive(:flight_fuel_burn).with(distance).and_return(1000)
      expect(Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:fuel)).to eq Calculation::FlightCostCalculator::FUEL_COST_PER_GALLON * 1000
    end
  end

  context "in_flight_service" do
    it "scales linearly with distance" do
      mock_model = instance_double(
        AircraftModel,
        **aircraft_model_attributes,
      )
      mock_airplane = instance_double(
        Airplane,
        aircraft_model: mock_model,
        **airplane_attributes,
      )

      distance = 100

      num_seats = (1..154).to_a.sample

      expect(mock_model).to receive(:flight_time_mins).with(distance).and_return(60)
      expect(mock_airplane).to receive(:num_seats).and_return(num_seats)
      expect(Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:in_flight_service)).to eq Calculation::FlightCostCalculator::SERVICE_COST_PER_HOUR * num_seats

      expect(mock_model).to receive(:flight_time_mins).with(distance).and_return(90)
      expect(mock_airplane).to receive(:num_seats).and_return(num_seats)
      assert_in_epsilon Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:in_flight_service), Calculation::FlightCostCalculator::SERVICE_COST_PER_HOUR * num_seats * 1.5, 0.000001
    end
  end

  context "ground_support" do
    distance = 1

    context "num_ramp_agents" do
      it "is one for planes without flight attendants" do
        aircraft_model_attributes[:num_flight_attendants] = 0

        mock_model = instance_double(
          AircraftModel,
          **aircraft_model_attributes,
        )
        mock_airplane = instance_double(
          Airplane,
          aircraft_model: mock_model,
          **airplane_attributes,
        )

        expect(mock_airplane).to receive(:num_seats).and_return(1)
        expect(Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:num_ramp_agents)).to eq 1
      end

      it "is two for planes with flight attendants" do
        aircraft_model_attributes[:num_flight_attendants] = 100

        mock_model = instance_double(
          AircraftModel,
          **aircraft_model_attributes,
        )
        mock_airplane = instance_double(
          Airplane,
          aircraft_model: mock_model,
          **airplane_attributes,
        )

        expect(mock_airplane).to receive(:num_seats).and_return(1)
        expect(Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:num_ramp_agents)).to eq 2
      end

      it "increases with plane size" do
        aircraft_model_attributes[:num_flight_attendants] = 1

        mock_model = instance_double(
          AircraftModel,
          **aircraft_model_attributes,
        )
        mock_airplane = instance_double(
          Airplane,
          aircraft_model: mock_model,
          **airplane_attributes,
        )

        expect(mock_airplane).to receive(:num_seats).and_return(Calculation::FlightCostCalculator::MARGINAL_RAMP_AGENT_PAX / 2 + 1)
        expect(Calculation::FlightCostCalculator.new(mock_airplane, distance).send(:num_ramp_agents)).to eq 3
      end
    end

    it "calculates correctly" do
      aircraft_model_attributes[:num_flight_attendants] = 1

      mock_model = instance_double(
        AircraftModel,
        **aircraft_model_attributes,
      )
      mock_airplane = instance_double(
        Airplane,
        aircraft_model: mock_model,
        **airplane_attributes,
      )

      allow(mock_airplane).to receive(:num_seats).and_return(Calculation::FlightCostCalculator::MARGINAL_RAMP_AGENT_PAX * Calculation::FlightCostCalculator::MARGINAL_GATE_AGENT_PAX)

      expected_ramp = 2 + Calculation::FlightCostCalculator::MARGINAL_GATE_AGENT_PAX
      expected_gate = 1 + Calculation::FlightCostCalculator::MARGINAL_RAMP_AGENT_PAX

      subject = Calculation::FlightCostCalculator.new(mock_airplane, distance)

      expect(subject.send(:num_ramp_agents)).to eq expected_ramp
      expect(subject.send(:num_gate_agents)).to eq expected_gate

      expect(subject.send(:ground_support)).to eq expected_ramp * Calculation::FlightCostCalculator::RAMP_AGENT_COST_PER_FLIGHT + expected_gate * Calculation::FlightCostCalculator::GATE_AGENT_COST_PER_FLIGHT
    end
  end
end
