class RoutesController < ApplicationController
  def index
    @game = Game.find(params[:game_id])
    @airline = Airline.find(params[:airline_id])
  end

  def select_route
    @game = Game.find(params[:game_id])
    @airports = Airport.select_options
    @origin = params[:origin] || 1
    @destination = params[:destination] || 2
    @errors = []
  end

  def update_price_or_frequency
    if params.include?(:economy_price) && params.include?(:premium_economy_price) && params.include?(:business_price)
      @route = AirlineRoute.find(params[:airline_route_id])
      @route.set_price(params[:economy_price], params[:premium_economy_price], params[:business_price])
    elsif params.include?(:service_quality)
      @route = AirlineRoute.find(params[:airline_route_id])
      @route.set_service_quality(params[:service_quality])
    elsif params.include?(:frequencies)
      @route = AirlineRoute.find(params[:airline_route_id])
      @airplane_route = AirplaneRoute.find_or_initialize_by(airplane_id: params[:airplane_id], route: @route)
      @airplane_route.set_frequency(params[:frequencies].to_i)
    end

    @game = Game.find(params[:game_id])
    @airplanes = @route.airplanes + @route.airplanes_available_to_add_service(@game)
    @revenue = RouteDollars.display_revenues_between_airports(@route.origin_airport, @route.destination_airport, @game.current_date)
    @all_service = AirlineRoute.operators_of_route(@route.origin_airport, @route.destination_airport, @game)
    @other_market_service = AirlineRoute.operators_of_other_market_routes(@route.origin_airport, @route.destination_airport, @game)
    render :view_route
  end

  def view_route
    @game = Game.find(params[:game_id])
    @route = if params[:origin_id].present? && params[:destination_id].present?
      airports = [Airport.find(params[:origin_id]), Airport.find(params[:destination_id])]
      origin = [Airport.find(params[:origin_id]), Airport.find(params[:destination_id])].min_by{ |a| a.iata }
      destination = [Airport.find(params[:origin_id]), Airport.find(params[:destination_id])].max_by{ |a| a.iata }
      if origin == destination
        @airports = Airport.select_options
        @origin = origin.id
        @destination = destination.id
        @errors = ["Origin airport and destination airport must be different to view a route"]
        render :select_route
      end
      AirlineRoute.find_or_create_by_airline_and_route(@game.user_airline, origin, destination)
    else
      referring_airline_route = AirlineRoute.find(params[:airline_route_id])
      AirlineRoute.find_or_create_by_airline_and_route(@game.user_airline, referring_airline_route.origin_airport, referring_airline_route.destination_airport)
    end
    @airplanes = @route.airplanes + @route.airplanes_available_to_add_service(@game)
    @revenue = RouteDollars.display_revenues_between_airports(@route.origin_airport, @route.destination_airport, @game.current_date)
    @all_service = AirlineRoute.operators_of_route(@route.origin_airport, @route.destination_airport, @game)
    @other_market_service = AirlineRoute.operators_of_other_market_routes(@route.origin_airport, @route.destination_airport, @game)
  end
end
