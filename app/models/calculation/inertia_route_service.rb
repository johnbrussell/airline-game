class Calculation::InertiaRouteService
  include Demandable

  INERTIA_PLANE_FUEL_BURN_CONSTANT = 118.4
  INERTIA_PLANE_MAX_NARROWBODY_SEATS = 199
  INERTIA_PLANE_SPEED = 556
  LOAD_FACTOR = 0.7
  MAX_PASSENGERS_PER_FA = 50
  REVENUE_PERCENTAGE = 0.5
  LONG_DISTANCE = 4000
  LONG_DISTANCE_BUSINESS_SEATS = 30
  LONG_DISTANCE_PREMIUM_ECONOMY_SEATS = 50
  LONG_DISTANCE_ECONOMY_SEATS = 225
  SHORT_DISTANCE = 100
  SHORT_DISTANCE_BUSINESS_SEATS = 0
  SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS = 8
  SHORT_DISTANCE_ECONOMY_SEATS = 57

  def business_fare
    if business_frequencies == 0
      0
    else
      (business_frequencies / desired_business_frequencies) * (business_revenue / desired_business_frequencies / business_seats_per_flight)
    end
  end

  def business_frequencies
    if business_seats_per_flight == 0
      0
    else
      (desired_business_frequencies / LOAD_FACTOR).ceil()
    end
  end

  def business_seats_per_flight
    if distance >= LONG_DISTANCE
      LONG_DISTANCE_BUSINESS_SEATS
    elsif distance >= SHORT_DISTANCE
      SHORT_DISTANCE_BUSINESS_SEATS + ((LONG_DISTANCE_BUSINESS_SEATS - SHORT_DISTANCE_BUSINESS_SEATS) * (distance - SHORT_DISTANCE) / (LONG_DISTANCE - SHORT_DISTANCE)).ceil()
    else
      (SHORT_DISTANCE_BUSINESS_SEATS * distance / SHORT_DISTANCE).ceil()
    end
  end

  def economy_fare
    if economy_frequencies == 0
      0
    else
      (economy_frequencies / desired_economy_frequencies) * (economy_revenue / desired_economy_frequencies / economy_seats_per_flight)
    end
  end

  def economy_frequencies
    if economy_seats_per_flight == 0
      0
    else
      (desired_economy_frequencies / LOAD_FACTOR).ceil()
    end
  end

  def economy_seats_per_flight
    if distance >= LONG_DISTANCE
      LONG_DISTANCE_ECONOMY_SEATS
    elsif distance >= SHORT_DISTANCE
      SHORT_DISTANCE_ECONOMY_SEATS + ((LONG_DISTANCE_ECONOMY_SEATS - SHORT_DISTANCE_ECONOMY_SEATS) * (distance - SHORT_DISTANCE) / (LONG_DISTANCE - SHORT_DISTANCE)).ceil()
    else
      (SHORT_DISTANCE_ECONOMY_SEATS * distance / SHORT_DISTANCE).ceil()
    end
  end

  def flight_cost
    @flight_cost ||= Calculation::FlightCostCalculator.new(inertia_airplane, distance).cost
  end

  def premium_economy_fare
    if premium_economy_frequencies == 0
      0
    else
      (premium_economy_frequencies / desired_premium_economy_frequencies) * (premium_economy_revenue / desired_premium_economy_frequencies / premium_economy_seats_per_flight)
    end
  end

  def premium_economy_frequencies
    if premium_economy_seats_per_flight == 0
      0
    else
      (desired_premium_economy_frequencies / LOAD_FACTOR).ceil()
    end
  end

  def premium_economy_seats_per_flight
    if distance >= LONG_DISTANCE
      LONG_DISTANCE_PREMIUM_ECONOMY_SEATS
    elsif distance >= SHORT_DISTANCE
      SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS + ((LONG_DISTANCE_PREMIUM_ECONOMY_SEATS - SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS) * (distance - SHORT_DISTANCE) / (LONG_DISTANCE - SHORT_DISTANCE)).ceil()
    else
      (SHORT_DISTANCE_PREMIUM_ECONOMY_SEATS * distance / SHORT_DISTANCE).ceil()
    end
  end

  private

    def business_flight_cost
      flight_cost.to_f * business_seats_per_flight * Airplane::BUSINESS_SEAT_SIZE / total_seat_area
    end

    def business_revenue
      revenue.max_business_class_revenue_per_week * REVENUE_PERCENTAGE
    end

    def desired_business_frequencies
      business_revenue.to_f / business_flight_cost
    end

    def desired_economy_frequencies
      economy_revenue.to_f / economy_flight_cost
    end

    def desired_premium_economy_frequencies
      premium_economy_revenue.to_f / premium_economy_flight_cost
    end

    def economy_flight_cost
      flight_cost.to_f * economy_seats_per_flight * Airplane::ECONOMY_SEAT_SIZE / total_seat_area
    end

    def economy_revenue
      revenue.max_economy_class_revenue_per_week * REVENUE_PERCENTAGE
    end

    def inertia_airplane
      Airplane.new(
        base_country_group: "foo",
        business_seats: business_seats_per_flight,
        construction_date: Date.today,
        economy_seats: economy_seats_per_flight,
        end_of_useful_life: Date.today + 1.day,
        premium_economy_seats: premium_economy_seats_per_flight,
        aircraft_model: AircraftModel.new(
          name: "foo",
          production_start_year: Date.today.year,
          floor_space: business_seats_per_flight * Airplane::BUSINESS_SEAT_SIZE + premium_economy_seats_per_flight * Airplane::PREMIUM_ECONOMY_SEAT_SIZE + economy_seats_per_flight * Airplane::ECONOMY_SEAT_SIZE,
          max_range: distance.ceil(),
          fuel_burn: (Math.sqrt(total_seats) * INERTIA_PLANE_FUEL_BURN_CONSTANT).ceil(),
          speed: INERTIA_PLANE_SPEED,
          num_aisles: total_seats > INERTIA_PLANE_MAX_NARROWBODY_SEATS ? 2 : 1,
          num_pilots: 2,
          num_flight_attendants: total_seats <= 19 ? 0 : (total_seats / MAX_PASSENGERS_PER_FA.to_f).ceil(),
          price: 1,
          takeoff_distance: 1,
          useful_life: 1,
        )
      )
    end

    def premium_economy_flight_cost
      flight_cost.to_f * premium_economy_seats_per_flight * Airplane::PREMIUM_ECONOMY_SEAT_SIZE / total_seat_area
    end

    def premium_economy_revenue
      revenue.max_premium_economy_class_revenue_per_week * REVENUE_PERCENTAGE
    end

    def revenue
      @revenue ||= Calculation::MaximumRevenuePotential.new(@origin, @destination, @current_date)
    end

    def total_seat_area
      economy_seats_per_flight * Airplane::ECONOMY_SEAT_SIZE + premium_economy_seats_per_flight * Airplane::PREMIUM_ECONOMY_SEAT_SIZE + business_seats_per_flight * Airplane::BUSINESS_SEAT_SIZE
    end

    def total_seats
      economy_seats_per_flight + premium_economy_seats_per_flight + business_seats_per_flight
    end
end
