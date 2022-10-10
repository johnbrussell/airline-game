class Calculation::MarketPopulation
  CAPITAL_GOVERNMENT_WORKERS = 10000

  def initialize(market, current_date)
    @market = market
    @current_date = current_date
  end

  def government_workers
    @market.is_national_capital ? CAPITAL_GOVERNMENT_WORKERS : 0
  end

  def population
    if most_recent_known_population.blank?
      next_known_population.population
    elsif next_known_population.blank?
      most_recent_known_population.population
    elsif @current_date.year == most_recent_known_population.year
      most_recent_known_population.population
    else
      most_recent_known_population.population * (population_growth_rate ** years_since_last_population_sample)
    end
  end

  def tourists
    if most_recent_known_tourists.blank?
      next_known_tourists.volume
    elsif next_known_tourists.blank?
      most_recent_known_tourists.volume
    elsif @current_date.year == most_recent_known_tourists.year
      most_recent_known_tourists.volume
    else
      most_recent_known_tourists.volume * (tourism_growth_rate ** years_since_last_tourists_sample)
    end
  end

  private

    def most_recent_known_population
      @most_recent_known_population ||= @market.populations.where("year <= ?", @current_date.year).max_by(&:year)
    end

    def most_recent_known_tourists
      @most_recent_known_tourists ||= @market.tourists.where("year <= ?", @current_date.year).max_by(&:year)
    end

    def next_known_population
      @next_known_population ||= @market.populations.where("year >= ?", @current_date.year).min_by(&:year)
    end

    def next_known_tourists
      @next_known_tourists ||= @market.tourists.where("year >= ?", @current_date.year).min_by(&:year)
    end

    def population_growth_rate
      (next_known_population.population.to_f / most_recent_known_population.population) ** (1.0 / years_between_population_sample)
    end

    def tourism_growth_rate
      (next_known_tourists.volume.to_f / most_recent_known_tourists.volume) ** (1.0 / years_between_tourism_sample)
    end

    def years_between_population_sample
      next_known_population.year - most_recent_known_population.year
    end

    def years_between_tourism_sample
      next_known_tourists.year - most_recent_known_tourists.year
    end

    def years_since_last_population_sample
      @current_date.year - most_recent_known_population.year
    end

    def years_since_last_tourists_sample
      @current_date.year - most_recent_known_tourists.year
    end
end
