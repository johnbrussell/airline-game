Rails.application.routes.draw do
  get "/", to: "home#index"

  resources :games do
    resources :airlines do
      resources :airplanes
    end

    namespace :new_airplanes do
      resources :airplanes
    end

    namespace :used_airplanes do
      resources :airplanes
    end

    get "/purchase_airplane", to: "airplanes#purchase"
    get "/lease_airplane", to: "airplanes#lease"
  end
end
