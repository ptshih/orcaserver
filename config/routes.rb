Orcapods::Application.routes.draw do
  
  resources :pod
  
## Register/signons
  match ':version/register', :to => 'login#register', :via => ["get","post"]  # CREATE: Register new user with access_token
  match ':version/session', :to => 'login#session', :via => ["get","post"] # SESSION: Start a new session for the current user
  match ':version/registerpush', :to => 'login#registerpush', :via => ["get","post"] # Start a new session for the current user

  
## Read
  match ':version/pods', :controller => 'pod', :action => 'index', :via => :get # get list of pods
  match ':version/pods/:pod_id/messages', :controller => 'pod', :action => 'message_index', :via => :get # get list of messages
  match ':version/pods/:pod_id/members', :controller => 'pod', :action => 'members', :via => :get # get list of members
  
## Writes
  # Create pod
  match ':version/pods/create', :controller => 'pod', :action =>'new', :via => ["get","post"]
  # Create message
  match ':version/pods/:pod_id/messages/create', :controller => 'pod', :action =>'message_new', :via => ["get","post"]
  # Mute pod
  match ':version/pods/:pod_id/mute/:hours', :controller => 'pod', :action =>'mute_pod', :via => ["get","post"]
  # Add user to pod
  match ':version/pods/:pod_id/user/:user_id/add', :controller => 'pod', :action =>'add_user', :via => ["get","post"]
  # Remove user to pod
  match ':version/pods/:pod_id/user/:user_id/remove', :controller => 'pod', :action =>'remove_user', :via => ["get","post"]
  # Change pod name
  match ':version/pods/:pod_id/change_name', :controller => 'pod', :action =>'change_pod_name', :via => ["get","post"]  

## Diffbot
  match ':version/diffbot', :controller => 'diffbot', :action =>'fetch_url', :via => ["get","post"]
  

  # http://localhost:3000/v1/pods
  # http://localhost:3000/v1/pods/1/messages

  # The priority is based upon order of creation:
  # first created -> highest priority.

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
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id(.:format)))'
end
