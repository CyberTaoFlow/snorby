Snorby::Application.routes.draw do

  resources :lookups
  
  resources :snmps do
    
    collection do
      post :mass_update
    end
    
  end

  match '/snmp_results', :controller => 'Snmps', :action => 'results'
  match '/trap_results', :controller => 'Traps', :action => 'results'

  match '/sensors/:sensor_id/active_rules'         , :controller => 'Rules', :action => 'active_rules'
  match '/sensors/:sensor_id/pending_rules'        , :controller => 'Rules', :action => 'pending_rules'
  match '/sensors/:sensor_id/update_rule_category' , :controller => 'Rules', :action => 'update_rule_category'
  match '/sensors/:sensor_id/update_rule_action'   , :controller => 'Rules', :action => 'update_rule_action'
  match '/sensors/:sensor_id/compile_rules'        , :controller => 'Rules', :action => 'compile_rules'
  match '/sensors/:sensor_id/discard_pending_rules', :controller => 'Rules', :action => 'discard_pending_rules'

  resources :rules

  # This feature is not ready yet
  # resources :notifications

  resources :jobs do
    member do
      get :last_error
      get :handler
    end
  end

  resources :classifications

  devise_for :users, :path_names => { :sign_in => 'login', 
    :sign_out => 'logout', 
    :sign_up => 'register' }, :controllers => { 
    :registrations => "registrations",
    :sessions => "sessions",
    :passwords => 'passwords'
  } do
    get "/login" => "devise/sessions#new"
    get '/logout', :to => "devise/sessions#destroy"
    get '/reset/password', :to => "devise/passwords#edit"
  end

  root :to => "page#dashboard"

	match '/sensors/update_parent', :controller => 'Sensors', :action => 'update_parent'

  resources :sensors do
    resources :rules
    resources :events
    resources :snmps
  end

  resources :settings do
    collection do
      get :restart_worker
      get :start_sensor_cache
      get :start_daily_cache
      get :start_geoip_update
      get :start_snmp
      get :start_worker
      get :stop_worker      
    end
  end
  
  resources :severities do
    
  end


  match '/dashboard', :controller => 'Page', :action => 'dashboard'
  match '/search', :controller => 'Page', :action => 'search'
  match '/results', :controller => 'Page', :action => 'results'
  match '/force/cache', :controller => "Page", :action => 'force_cache'
  
  match ':controller(/:action(/:sid/:cid))', :controller => 'Events'

  resources :events do
    
    resources :notes do
      
    end
    
    collection do
      get :view
      get :create_mass_action
      post :mass_action
      get :create_email
      post :email
      get :hotkey
      post :export
      get :lookup
      get :rule
      get :packet_capture
      get :history
      post :classify
      post :mass_update
      get :queue
      post :favorite
      get :last
      get :since
      get :activity
    end
    
  end
  
  resources :notes

  resources :users do
    collection do
      post :toggle_settings
      post :remove
      post :add
    end
  end

  resources :page do
    collection do
      get :search
      get :results
    end
  end

end
