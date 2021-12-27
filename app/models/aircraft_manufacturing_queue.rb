class AircraftManufacturingQueue < ApplicationRecord
  belongs_to :game
  has_many :airplanes
  has_many :undelivered_aircraft, ->(amq) { where("construction_date > ?", amq.game.current_date) }, class_name: "Airplane"

  DAYS_PER_MONTH = 365.24 / 12
  LOW_PRODUCTION_RATES = [1/6.0, 1/4.0, 1/3.0, 1/2.0]
  PERCENT_UNBOUGHT_TO_DECREASE_PRODUCTION = 0.5
  PERCENT_UNBOUGHT_TO_INCREASE_PRODUCTION = 0.95
  PRODUCTION_RATE_CHANGE_INTERVAL = 0.5
  PRODUCTION_START_ADVANCE_NOTICE_MONTHS = 6.0
  QUEUE_LENGTH_MONTHS = 12.0
  START_PRODUCTION_RATE = 1.0

  def add_to_production_queue(model)
    (1..(num_to_add_to_production_queue)).to_a.each do |plane_number|
      create_new_airplane(model, last_unbuilt_aircraft.construction_date + (days_between_airframes * plane_number).days)
    end
  end

  def optimize_production_rate
    if percent_unbought > PERCENT_UNBOUGHT_TO_INCREASE_PRODUCTION
      increase_production_rate
    elsif percent_unbought < PERCENT_UNBOUGHT_TO_DECREASE_PRODUCTION
      decrease_production_rate
    end
  end

  def start_production(aircraft_model)
    if airplanes.none?
      start_family_production(aircraft_model)
    else
      start_model_production(aircraft_model)
    end
  end

  private

    def create_new_airplane(model, construction_date)
      Airplane.create!(
        aircraft_model_id: model.id,
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: (model.floor_space / Airplane::ECONOMY_SEAT_SIZE).floor(),
        construction_date: construction_date,
        end_of_useful_life: construction_date + model.useful_life.years,
        aircraft_manufacturing_queue_id: id,
      )
    end

    def create_new_airplane_in_future(model, months_until_delivery)
      create_new_airplane(model, game.current_date + (months_until_delivery * DAYS_PER_MONTH).ceil().days)
    end

    def days_between_airframes
      DAYS_PER_MONTH / production_rate
    end

    def days_in_production_queue
      (last_unbuilt_aircraft.construction_date - game.current_date).to_i
    end

    def decrease_production_rate
      if production_rate > LOW_PRODUCTION_RATES.max + PRODUCTION_RATE_CHANGE_INTERVAL
        update!(production_rate: production_rate - PRODUCTION_RATE_CHANGE_INTERVAL)
      else
        decrease_production_rate_using_low_rate_scale
      end
    end

    def decrease_production_rate_using_low_rate_scale
      if production_rate < LOW_PRODUCTION_RATES.min * 1.001
        update!(production_rate: 0)
      else
        update!(production_rate: LOW_PRODUCTION_RATES.select { |rate| rate < production_rate * 0.999 }.max)
      end
    end

    def increase_production_rate
      if 0 < production_rate && production_rate < LOW_PRODUCTION_RATES.max * 0.999
        update!(production_rate: LOW_PRODUCTION_RATES.select { |rate| rate > production_rate * 1.001 }.min)
      elsif 0 < production_rate
        update!(production_rate: production_rate + PRODUCTION_RATE_CHANGE_INTERVAL)
      end
    end

    def last_unbuilt_aircraft
      undelivered_aircraft.max_by(&:construction_date)
    end

    def num_months_to_produce_for_extant_family
      [[QUEUE_LENGTH_MONTHS, time_to_last_unbuilt_aircraft_months].max - PRODUCTION_START_ADVANCE_NOTICE_MONTHS, 0].max
    end

    def num_bought_undelivered_aircraft
      undelivered_aircraft.count(&:has_operator?)
    end

    def num_to_add_to_production_queue
      [((QUEUE_LENGTH_MONTHS + 1) * DAYS_PER_MONTH - days_in_production_queue) * (production_rate / DAYS_PER_MONTH), 1].max
    end

    def percent_unbought
      num_bought_undelivered_aircraft.to_f / undelivered_aircraft.count
    end

    def start_family_production(aircraft_model)
      (0..(QUEUE_LENGTH_MONTHS * START_PRODUCTION_RATE)).to_a.each do |month|
        create_new_airplane_in_future(aircraft_model, PRODUCTION_START_ADVANCE_NOTICE_MONTHS + month.to_f / START_PRODUCTION_RATE)
      end
      update!(production_rate: START_PRODUCTION_RATE)
    end

    def start_model_production(aircraft_model)
      (0..(num_months_to_produce_for_extant_family * START_PRODUCTION_RATE)).to_a.each do |month|
        create_new_airplane_in_future(aircraft_model, PRODUCTION_START_ADVANCE_NOTICE_MONTHS + month.to_f / START_PRODUCTION_RATE)
      end
      update!(production_rate: [START_PRODUCTION_RATE, production_rate].max)
    end

    def time_to_last_unbuilt_aircraft_months
      if last_unbuilt_aircraft.present?
        ((last_unbuilt_aircraft.construction_date - game.current_date).to_f / DAYS_PER_MONTH).floor()
      else
        0
      end
    end
end
