Rails.application.routes.draw do
  get "/", to: "home#index"
  get "/home", to: "home#index"
end
