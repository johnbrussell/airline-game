Rails.application.routes.draw do
  get "/", to: "home#index"

  resources :games do
    resources :airlines do
      resources :airplanes do
        get "/change_configuration", to: "airplanes#change_configuration"
        patch "/change_configuration", to: "airplanes#update"
      end

      resources :slots
      get "/return_a_slot", to: "slots#index"
      patch "/return_a_slot", to: "slots#return"

      get "/routes", to: "routes#index"
    end

    resources :airplanes do
      get "/purchase", to: "airplanes#purchase_information"
      get "/lease", to: "airplanes#lease_information"
      patch "/purchase", to: "airplanes#purchase"
      patch "/lease", to: "airplanes#lease"
    end

    namespace :new_airplanes do
      resources :airplanes
    end

    namespace :used_airplanes do
      resources :airplanes
    end

    get "/select_airport", to: "airports#select_airport"
    resources :airports do
      get "/build_a_gate", to: "airports#show"
      patch "/build_a_gate", to: "airports#build_gate"
      get "/lease_a_slot", to: "airports#show"
      patch "/lease_a_slot", to: "airports#lease_slot"
    end

    get "/select_route", to: "routes#select_route"
    resources :airline_routes do
      get "/add_flights", to: "routes#view_route"
      patch "/add_flights", to: "routes#update_price_or_frequency"
    end
  end
end
