class RoutesController < ApplicationController
  def add_flights
    @game = Game.find(params[:game_id])
    airports = [Airport.find(params[:origin_id]), Airport.find(params[:destination_id])]
    @origin = airports.min_by { |a| a.iata }
    @destination = airports.max_by { |a| a.iata }
  end

  def select_route
    @game = Game.find(params[:game_id])
    @airports = Airport.select_options
  end

  def view_route
    @game = Game.find(params[:game_id])
    airports = [Airport.find(params[:origin_id]), Airport.find(params[:destination_id])]
    @origin = airports.min_by { |a| a.iata }
    @destination = airports.max_by { |a| a.iata }
    @revenue = Calculation::MaximumRevenuePotential.new(@origin, @destination, @game.current_date)
  end
end
