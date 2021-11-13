module Populatable
  extend ActiveSupport::Concern

  include Demandable

  private

    def airport_population
      available_catchment / 100.0 * market_population
    end

    def available_catchment
      @destination.exclusive_catchment + destination_market.shared_catchment
    end

    def market_population
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

    def most_recent_known_population
      @most_recent_known_population ||= destination_market.populations.where("year <= ?", @current_date.year).max_by(&:year)
    end

    def next_known_population
      @next_known_population ||= destination_market.populations.where("year >= ?", @current_date.year).min_by(&:year)
    end

    def population_growth_rate
      (next_known_population.population.to_f / most_recent_known_population.population) ** (1.0 / years_between_population_sample)
    end

    def years_between_population_sample
      next_known_population.year - most_recent_known_population.year
    end

    def years_since_last_population_sample
      @current_date.year - most_recent_known_population.year
    end
end