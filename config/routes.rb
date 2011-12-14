Snorby::Application.routes.draw do

  resources :lookups
  
  resources :snmps do
    
    collection do
      post :mass_update
    end
    
  end

  match '/snmp_results', :controller => 'Snmps', :action => 'results'
  match '/trap_results', :controller => 'Traps', :action => 'results'

  match '/sensors/:sensor_id/update_rule_action'   , :controller => 'Rules', :action => 'update_rule_action'
  match '/sensors/:sensor_id/update_rules_action'  , :controller => 'Rules', :action => 'update_rules_action'
  match '/sensors/:sensor_id/update_rule_category' , :controller => 'Rules', :action => 'update_rule_category'
  match '/sensors/:sensor_id/update_rule_group'    , :controller => 'Rules', :action => 'update_rule_group'
  match '/sensors/:sensor_id/update_rule_family'   , :controller => 'Rules', :action => 'update_rule_family'
  match '/sensors/:sensor_id/update_rule_details'  , :controller => 'Rules', :action => 'update_rule_details'

  resources :rules do

    collection do
      post :mass_update
    end

  end

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

  resources :sensors do
    get :update_dashboard_info
    get :update_dashboard_rules
    get :update_dashboard_load
    get :update_dashboard_hardware

    collection do
      get :update_parent
    end

    resources :rules do
      collection do
        get :active_rules
        get :pending_rules
        get :compile_rules
        get :discard_pending_rules
        get :compilations
      end
    end
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
