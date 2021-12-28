class UsedAirplanes::AirplanesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @new_airplanes = Airplane.all_available_new_airplanes(@game)
    @used_airplanes = Airplane.all_available_used_airplanes(@game)
  end
end
