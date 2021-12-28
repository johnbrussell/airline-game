class AirplanesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
    @airplanes = Airplane.
      joins(aircraft_model: :family).
      where(operator_id: @airline.id).
      where("construction_date <= ?", @game.current_date).
      order("aircraft_families.manufacturer", "aircraft_families.name", "aircraft_models.name", "construction_date DESC")
  end
end
