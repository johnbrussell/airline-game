Rails.application.routes.draw do
  get "/", to: "games#index"
  get "/home", to: "home#index"
end
