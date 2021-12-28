class NewAirplanes::AirplanesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @new_airplanes = Airplane.all_available_new_airplanes(@game)
  end
end
