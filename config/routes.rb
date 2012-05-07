Owgm::Application.routes.draw do
  # The priority is based upon order of creation:
  # first created -> highest priority.

  devise_for :users

  resources :access_points, :only => [:index]

  resources :configurations, :only => [:edit, :update]

  resources :wisps, :only => :index do

    resources :access_points, :only => [:index, :show] do
      resource :property_set, :only => :update
    end

    resources :activity_histories, :only => :index
    match 'access_points/:access_point_id/activities' => 'activities#show', :as => :access_point_activities
    match 'access_points/:access_point_id/activity_histories' => 'activity_histories#show', :as => :access_point_activity_histories
    match 'access_points/:access_point_id/associated_user_counts' => 'associated_user_counts#show',
          :as => :associated_user_counts
    match 'access_points/:access_point_id/associated_user_count_histories' => 'associated_user_count_histories#show',
          :as => :associated_user_count_histories
    match 'availability_report' => 'activity_histories#index', :as => :availability_report
  end

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  root :to => "wisps#index"

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
