class AircraftManufacturingQueue < ApplicationRecord
  belongs_to :game
  has_many :airplanes

  DAYS_PER_MONTH = 365.24 / 12
  PRODUCTION_START_ADVANCE_NOTICE_MONTHS = 6.0
  QUEUE_LENGTH_MONTHS = 12.0
  START_PRODUCTION_RATE = 1.0

  def start_production(aircraft_model)
    if airplanes.none?
      start_family_production(aircraft_model)
    else
      start_model_production(aircraft_model)
    end
  end

  private

    def create_new_airplane(model, months_until_delivery)
      Airplane.create!(
        aircraft_model_id: model.id,
        business_seats: 0,
        premium_economy_seats: 0,
        economy_seats: (model.floor_space / Airplane::ECONOMY_SEAT_SIZE).floor(),
        construction_date: game.current_date + (months_until_delivery * DAYS_PER_MONTH).ceil().days,
        aircraft_manufacturing_queue_id: id,
      )
    end

    def last_unbuilt_aircraft
      airplanes.select { |airplane| airplane.construction_date > game.current_date }.max_by(&:construction_date)
    end

    def num_months_to_produce_for_extant_family
      [[QUEUE_LENGTH_MONTHS, time_to_last_unbuilt_aircraft_months].max - PRODUCTION_START_ADVANCE_NOTICE_MONTHS, 0].max
    end

    def start_family_production(aircraft_model)
      (0..(QUEUE_LENGTH_MONTHS * START_PRODUCTION_RATE)).to_a.each do |month|
        create_new_airplane(aircraft_model, PRODUCTION_START_ADVANCE_NOTICE_MONTHS + month.to_f / START_PRODUCTION_RATE)
      end
      update!(production_rate: START_PRODUCTION_RATE)
    end

    def start_model_production(aircraft_model)
      (0..(num_months_to_produce_for_extant_family * START_PRODUCTION_RATE)).to_a.each do |month|
        create_new_airplane(aircraft_model, PRODUCTION_START_ADVANCE_NOTICE_MONTHS + month.to_f / START_PRODUCTION_RATE)
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
