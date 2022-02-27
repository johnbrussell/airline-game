class Calculation::FlightCostCalculator
  FA_HOURLY_COST = 60.0
  FUEL_COST_PER_GALLON = 5
  GATE_AGENT_COST_PER_FLIGHT = 105
  MARGINAL_GATE_AGENT_PAX = 50
  MARGINAL_RAMP_AGENT_PAX = 75
  PILOT_HOURLY_COST = 230.0
  RAMP_AGENT_COST_PER_FLIGHT = 35
  SERVICE_COST_PER_HOUR = 0.17

  def initialize(airplane, distance, service_quality)
    @airplane = airplane
    @distance = distance
    @service_quality = service_quality
  end

  def cost
    pilots +
      flight_attendants +
      fuel +
      in_flight_service +
      ground_support
  end

  private

    def flight_attendants
      FA_HOURLY_COST / 60 * @airplane.aircraft_model.num_flight_attendants * flight_time_mins
    end

    def flight_time_mins
      @flight_time_mins ||= @airplane.aircraft_model.flight_time_mins(@distance)
    end

    def fuel
      @airplane.aircraft_model.flight_fuel_burn(@distance) * FUEL_COST_PER_GALLON
    end

    def ground_support
      num_gate_agents * GATE_AGENT_COST_PER_FLIGHT + num_ramp_agents * RAMP_AGENT_COST_PER_FLIGHT
    end

    def in_flight_service
      SERVICE_COST_PER_HOUR / 60 * flight_time_mins * @airplane.num_seats * @service_quality
    end

    def num_gate_agents
      (1 + @airplane.num_seats.to_f / MARGINAL_GATE_AGENT_PAX).round
    end

    def num_ramp_agents
      base_ramp_agents = @airplane.aircraft_model.num_flight_attendants > 0 ? 2 : 1
      (base_ramp_agents + @airplane.num_seats.to_f / MARGINAL_RAMP_AGENT_PAX).round
    end

    def pilots
      PILOT_HOURLY_COST / 60 * @airplane.aircraft_model.num_pilots * flight_time_mins
    end
end
