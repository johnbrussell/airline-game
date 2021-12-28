class NewAirplanes::AirplanesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @new_airplanes = Airplane.available_new(@game)
  end
end
