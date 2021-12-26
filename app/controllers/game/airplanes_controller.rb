class Game::AirplanesController < ApplicationController
  def index
    @game = game
    @airplanes = airplanes
  end

  private

    def airplanes
      @airplanes ||= Airplane.all
    end

    def game
      @game ||= Game.find(params[:game_id])
    end
end
