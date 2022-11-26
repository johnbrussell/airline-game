class Calculation::RouteReputation
  REPUTATION_WEIGHTS = {
    fare: 0.3,
    frequency: 0.3,
    ifs: 0.1,
    legroom: 0.3,
  }
  FREQUENCIES_FOR_MAX_REPUTATION = 245
  MIN_REPUTATION = 1
  MAX_REPUTATION = 4

  delegate :airline,
           :fare,
           :ifs,
           :legroom,
           to: :@reputation_data

  def initialize(reputation_data, comparison_reputation_datas)
    @reputation_data = reputation_data
    @comparison_reputation_datas = comparison_reputation_datas
  end

  def reputation
    REPUTATION_WEIGHTS[:fare] * fare_reputation + REPUTATION_WEIGHTS[:frequency] * frequency_reputation + REPUTATION_WEIGHTS[:ifs] * ifs_reputation + REPUTATION_WEIGHTS[:legroom] * legroom_reputation
  end

  private

    def fare_reputation
      scale_reputation(1 - ((fare / max_route_fare.to_f) ** 2), 0, 1)
    end

    def frequency_reputation
      airline_airplanes = @comparison_reputation_datas.select { |crd| crd.airline == airline }
      airline_frequencies = airline_airplanes.sum(&:frequencies)
      scale_reputation([airline_frequencies, FREQUENCIES_FOR_MAX_REPUTATION].min, 1, FREQUENCIES_FOR_MAX_REPUTATION)
    end

    def ifs_reputation
      scale_reputation(ifs, AirlineRoute::MIN_SERVICE_QUALITY, AirlineRoute::MAX_SERVICE_QUALITY)
    end

    def inertia_route
      @inertia_route ||= calculate_inertia_route
    end

    def legroom_reputation
      scale_reputation(legroom, 0, 1)
    end

    def max_route_fare
      @comparison_reputation_datas.map(&:fare).max
    end

    def scale_reputation(input_reptuation, input_min, input_max)
      (input_reptuation - input_min) * (MAX_REPUTATION - MIN_REPUTATION) / (input_max - input_min).to_f + MIN_REPUTATION
    end
end
