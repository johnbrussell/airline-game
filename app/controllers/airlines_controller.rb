class AirlinesController < ApplicationController
  def index
    @game = params[:game_id]
    @airlines = Airline.all # should be @game.airlines, not Airline.all
  end
end
