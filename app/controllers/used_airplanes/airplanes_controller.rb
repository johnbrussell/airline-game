class UsedAirplanes::AirplanesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @used_airplanes = Airplane.available_used(@game)
  end
end
