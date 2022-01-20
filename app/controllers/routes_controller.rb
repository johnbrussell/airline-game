class RoutesController < ApplicationController
  def select_route
    @game = Game.find(params[:game_id])
  end
end
