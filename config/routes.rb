Rails.application.routes.draw do
  get "/", to: "home#index"

  resources :games do
    resources :airlines do
      resources :airplanes
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
    resources :airports
  end
end
