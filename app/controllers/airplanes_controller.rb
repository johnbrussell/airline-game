class AirplanesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
    @airplanes = Airplane.
      with_operator(@airline.id).
      where("construction_date <= ?", @game.current_date).
      neatly_sorted
  end
end
