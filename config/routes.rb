Owgm::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  devise_for :users
  resources :users

  resources :access_points, :only => [:index] do
    collection do
      post 'change_property' => 'access_points#batch_change_property'
      get 'select_group' => 'access_points#batch_select_group'
    end
  end

  resources :configurations, :only => [:edit, :update]

  resources :wisps, :only => :index do

    # TODO: check here
    match 'reset_favourites' => 'access_points#reset_favourites', :as => :reset_favourites
    match 'access_points_favourite' => 'access_points#index', :as => :access_points_favourite, :defaults => { :filter => 'favourite' }

    member do
      get 'select_group' => 'access_points#batch_select_group'
    end

    match 'groups' => 'groups#list', :as => :groups, :via => [:get]
    match 'groups/:group_id/access_points' => 'access_points#index', :as => :group_access_points, :via => [:get]

    resources :access_points, :only => [:index, :show] do

      resource :property_set, :only => :update

      member do
        post 'toggle_public'
        post 'toggle_favourite'
        get 'last_logins'
      end
    end

    resources :activity_histories, :only => :index

    match 'access_points/:access_point_id/activities' => 'activities#show', :as => :access_point_activities
    match 'access_points/:access_point_id/activity_histories' => 'activity_histories#show', :as => :access_point_activity_histories
    match 'access_points/:access_point_id/associated_user_counts' => 'associated_user_counts#show',
          :as => :associated_user_counts
    match 'access_points/:access_point_id/associated_user_count_histories' => 'associated_user_count_histories#show',
          :as => :associated_user_count_histories
    match 'availability_report' => 'activity_histories#index', :as => :availability_report
    match 'export' => 'activity_histories#export', :as => :export, :via => [:post]
    match 'send_report' => 'activity_histories#send_report', :as => :send_report

    match 'access_points/:access_point_id/select_group' => 'access_points#select_group', :as => :access_point_select_group, :via => [:get]
    match 'access_points/:access_point_id/change_group/:group_id' => 'access_points#change_group', :as => :access_point_change_group, :via => [:post]
    match 'access_points/:access_point_id/edit_ap_alert_settings' => 'access_points#edit_ap_alert_settings', :as => :access_point_edit_ap_alert_settings, :via => [:post]

    # OWUMS graphs
    match 'stats/logins.json' => 'stats#logins', :as => :logins_json, :via => [:get]
    match 'stats/traffic.json' => 'stats#traffic', :as => :traffic_json, :via => [:get]
    match 'stats/export' => 'stats#export', :as => :export_stats, :via => [:post]

    # Datawarehouse graphs
    match 'stats/activities.json' => 'stats#activities', :as => :activities_json, :via => [:get]
  end

  resources :groups, :only => [:index, :new, :edit, :create, :update, :destroy] do
    member do
      post 'toggle_monitor'
      post 'toggle_count_stats'
    end
  end

  match 'wisps/' => 'wisps#index', :via => [:get]

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "application#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
