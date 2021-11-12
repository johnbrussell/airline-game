class Calculation::DemandCurve
  SHORT_CONSTANTS = { :business => 1.3223140496 }
  SHORT_EXPONENTS = { :business => 2 }
  SHORT_SIGNIFICANCES = { :business => 10 ** -3 }
  SHORT_THRESHOLD_DISTANCES = { :business => 275 }
  LONG_THRESHOLD_DISTANCES = { :business => 400 }

  def initialize(distance, curve_type)
    @distance = distance
    @curve_type = curve_type
  end

  def relative_demand
    if @distance < short_threshold_distance
      short
    elsif @distance > long_threshold_distance
      long
    else
      moderate
    end
  end

  def relative_demand_island
    if @distance < short_threshold_distance
      short_island
    else
      relative_demand
    end
  end

  private

    def long
      long_threshold_distance * 100 / @distance
    end

    def long_threshold_distance
      @long_threshold_distance ||= LONG_THRESHOLD_DISTANCES.fetch(@curve_type)
    end

    def moderate
      100
    end

    def short
      short_constant * (@distance ** short_exponent) * short_significance
    end

    def short_constant
      @short_constant ||= SHORT_CONSTANTS.fetch(@curve_type)
    end

    def short_exponent
      @short_exponent ||= SHORT_EXPONENTS.fetch(@curve_type)
    end

    def short_island
      short_threshold_distance * 100 / @distance
    end

    def short_significance
      @short_significance ||= SHORT_SIGNIFICANCES.fetch(@curve_type)
    end

    def short_threshold_distance
      @short_threshold_distance ||= SHORT_THRESHOLD_DISTANCES.fetch(@curve_type)
    end
end
