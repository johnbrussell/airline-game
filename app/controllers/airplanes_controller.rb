class AirplanesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
    @airplanes = Airplane.where(operator_id: @airline.id).where("construction_date <= ?", @game.current_date)
  end
end
