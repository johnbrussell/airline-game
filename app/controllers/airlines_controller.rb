class AirlinesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airlines = @game.airlines
  end

  def show
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:id])
  end
end
