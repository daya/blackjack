Rails.application.routes.draw do
  get "/wallet", to: "wallet#show", as: :show_my_wallet

  resources :games, only: [:new, :create, :show] do
    member do
      post :hit
      post :no_more
    end
  end

  root "games#new"
end