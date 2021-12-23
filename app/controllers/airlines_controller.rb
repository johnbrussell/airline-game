class AirlinesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airlines = @game.airlines
  end
end
