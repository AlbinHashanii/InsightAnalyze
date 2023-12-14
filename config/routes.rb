Rails.application.routes.draw do
  require 'sidekiq/web'
  get 'sessions/new'
  get 'sessions/create'
  root 'home_page#index'

  mount Sidekiq::Web => '/sidekiq'

  devise_for :users, path: '', path_names: {
    sign_in: 'login',
    sign_out: 'logout',
    sign_up: 'register'
  }, controllers: {
    sessions: 'users/sessions',
    registrations: 'users/registrations'
  }


  namespace :news do
    get '/add_rss', to: 'rss#index'
    get '/all', to: 'news#index'
  end

  get '/items', to: 'all_items#item_index'
  post '/search_items', to: 'all_items#search'
  get '/item/:id', to: 'all_items#show', as: 'item'


  get '/sources', to: 'sources#index'
  get '/add_source', to: 'sources#index_2'
  post '/create_source', to: 'sources#create'

  post '/detect', to: 'detect_item#index'
  get '/informations', to: 'information#information'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
end
