Rails.application.routes.draw do
  get "/", to: "home#index"
  get "/games/:id", to: "games#index"
end
