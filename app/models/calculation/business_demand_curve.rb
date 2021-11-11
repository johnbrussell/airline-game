class Calculation::BusinessDemandCurve
  SHORT_CONSTANT = 1.3223140496
  SHORT_EXPONENT = 2
  SHORT_SIGNIFICANCE = 10 ** -3
  SHORT_THRESHOLD_DISTANCE = 275
  LONG_THRESHOLD_DISTANCE = 400

  def initialize(distance)
    @distance = distance
  end

  def relative_demand
    if @distance < SHORT_THRESHOLD_DISTANCE
      short
    elsif @distance > LONG_THRESHOLD_DISTANCE
      long
    else
      moderate
    end
  end

  def relative_demand_island
    if @distance < SHORT_THRESHOLD_DISTANCE
      short_island
    else
      relative_demand
    end
  end

  private

    def long
      LONG_THRESHOLD_DISTANCE * 100 / @distance
    end

    def moderate
      100
    end

    def short
      SHORT_CONSTANT * (@distance ** SHORT_EXPONENT) * SHORT_SIGNIFICANCE
    end

    def short_island
      SHORT_THRESHOLD_DISTANCE * 100 / @distance
    end
end
