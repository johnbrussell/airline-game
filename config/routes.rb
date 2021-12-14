Rails.application.routes.draw do
  get "/", to: "home#index"

  resources :games do
    resources :airlines
  end
end
