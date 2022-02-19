class RoutesController < ApplicationController
  def add_airplane_flights
    @route = AirlineRoute.find(params[:route_id])
    @airplane_route = AirplaneRoute.find_or_initialize_by(airplane_id: params[:airplane_id], route: @route)

    @airplane_route.set_frequency(params[:frequencies].to_i)

    @game = Game.find(params[:game_id])
    @airplanes = @route.airplanes + @route.airplanes_available_to_add_service
    @revenue = Calculation::MaximumRevenuePotential.new(@route.origin_airport, @route.destination_airport, @game.current_date)
    render :view_route
  end

  def add_flights
    @game = Game.find(params[:game_id])
    airports = [Airport.find(params[:origin_id]), Airport.find(params[:destination_id])]
    origin = airports.min_by { |a| a.iata }
    destination = airports.max_by { |a| a.iata }
    @route = AirlineRoute.find_or_create_by_airline_and_route(@game.user_airline, origin, destination)
    @airplanes = @route.airplanes + @route.airplanes_available_to_add_service
  end

  def select_route
    @game = Game.find(params[:game_id])
    @airports = Airport.select_options
  end

  def view_route
    @game = Game.find(params[:game_id])
    airports = [Airport.find(params[:origin_id]), Airport.find(params[:destination_id])]
    origin = airports.min_by { |a| a.iata }
    destination = airports.max_by { |a| a.iata }
    @route = AirlineRoute.find_or_create_by_airline_and_route(@game.user_airline, origin, destination)
    @airplanes = @route.airplanes + @route.airplanes_available_to_add_service
    @revenue = Calculation::MaximumRevenuePotential.new(origin, destination, @game.current_date)
  end
end
