Rails.application.routes.draw do
  get "/", to: "home#index"

  resources :games do
    resources :airlines do
      resources :airplanes
    end

    namespace :game do
      resources :airplanes
    end
  end
end
