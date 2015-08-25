## Storedom

Storedom is a simplistic e-commerce application used
for various lessons and tutorials at Turing.

### Setup

To get set up with the storedom application, clone it
via `git` and pull in gem dependencies with `bundler`:

```
git clone https://github.com/turingschool-examples/storedom.git
cd storedom
bundle
```

And set up the database and included seed records:

```
bundle exec rake db:setup
```

Notes: https://www.dropbox.com/s/kpm2ddj6k08hzrk/Turing%20-%20Understanding%20Multitenancy%20%28Notes%29.pages?dl=0
Lesson Plan: https://github.com/turingschool/lesson_plans/blob/master/ruby_03-professional_rails_applications/understanding_multitenancy.markdown
reference:

In this lesson, you will learn how to modify a Rails app to accept multiple stores, or tenants.

# Learning Goals

Understand why apps implement multi-tenancy at a high level
Understand how multi-tenancy is implemented at the routes level
Understand how multi-tenancy is implemented at a database level
Understand how multi-tenancy is handled at the controller level

Modify the Router to accept different tennants and store them.
Adding the controllers
Creating the moddels

**Multitenancy scales really well!**

With Multitanancy and software in the cloud, we can scale to millions of tennants as long as we can afford more servers (in the cloud)

The other approach is multi-instance architectures: When you download copies of the same software, whereas multitenancy is SaaS.

## Examples
Every store on Amazon is a tenant.
Different shops and makers on Etsy, each is a tenant
Organizations, collaborators and users included. on GitHub

## Modifying Storedom:
Changing the Router, Models and Controllers

Dream of the ideal URL you want to see in your browser and work back from that.

Controller modifying: you'll break a bunch of helpers ...
Use feature tests to guide you through the process. The app will be broken frequently so get comfortable with that. Follow the feature test through.

# Step 1

### Modify the Router

From this origionally ... `toutes.rb`
```
Rails.application.routes.draw do
  root 'items#index'

  resources :items,  only: [:index, :show]
  resources :orders, only: [:index, :show]
  resources :users,  only: [:index, :show]
end

```

to this ...

```
Rails.application.routes.draw do
  root 'items#index'

  namespece: store do
    resources :items,  only: [:index, :show]
    resources :orders, only: [:index, :show]
    resources :users,  only: [:index, :show]
  end
end

```

actually, so we don't break the existing routes ... do this
```
Rails.application.routes.draw do
  root 'items#index'

  resources :items,  only: [:index, :show]
  resources :orders, only: [:index, :show]
  resources :users,  only: [:index, :show]

  namespace :stores do
    resources :items, only: [:index, :show]
  end
end
```

When we `rake routes` we see `stores_items GET  /stores/items(.:format)     stores/items#index` and this is inaccurate bcuz we wan't `store_item`

so ...
```
Rails.application.routes.draw do
  root 'items#index'

  resources :items,  only: [:index, :show]
  resources :orders, only: [:index, :show]
  resources :users,  only: [:index, :show]

  namespace :stores, path: ":store", as: :store do
    resources :items, only: [:index, :show]
  end
end
```
... The `as` changes the URL helper
Namespace modifies the struture of the controllers. IE. with namespace, it creates the filepath`stores/items_controller.rb` ... scope doesn't `items_controller.rb`


### Now we need to add the controllers

We want the root to list all the stores we have in our system.

```
Rails.application.routes.draw do
  root 'stores#index'

  resources :items,  only: [:index, :show]
  resources :orders, only: [:index, :show]
  resources :users,  only: [:index, :show]

  namespace :stores, path: ":store", as: :store do
    resources :items, only: [:index, :show]
  end
end
```

Now we add the controllers`rails g controller stores`
Then create the items controller with `rails g controller stores/items`

Now we have controllers that match the structure we need.

Now the model: `rails g model store name url`
and migrate `rake db:migrate`

**Add a store**
Open the console: `rails c`
Create a store: `Store.create(name: "Marla's Running Shoes", url: "marla-s-running-shoes")`
*note: special characters get replaces by dashes. We'll have a method that cleans this up.*

Missing template: `touch app/views/stores/index.html.erb`

in the index
```
<div class="container">
  <% @stores.each do |store| %>
    <h1><%= store.name %></h1>
  <% end %>
</div>
```

In the `stores_controller.rb`:
```
class StoresController < ApplicationController
  def index
    @stores = Store.all
  end
end

```

If we have two stores:
Marla's Running Shoes
and
Marla S Running Shoes
... if we try to parameterize these names, the URL will be the same.
do fix this, go to the store model and add validation for the presence of the name and validation that the url is present and it's unique
```
class Store < ActiveRecord::Base
  validates :name, presence: true
  validates :url, presence: true, uniqueness: true
end
```
In the store model, create a method
```
  before_validation :generate_url

  def generate_url
    self.url = name.parameterize
  end
```
This parameterizes the sotre name into the URL so every time we create a store, the URL is generated automatically.
so when we `Store.create(name: "Dmitry's Babushkas")`
we get `[["created_at", "2015-08-25 15:43:08.206741"], ["name", "Dmitry's Babushkas"], ["updated_at", "2015-08-25 15:43:08.206741"], ["url", "dmitry-s-babushkas"]]`

so if we type, `Store.create(name: "Dmitry S Babushkas")` ... it doesn't create a new store.

....
** now our goal is to visit `localhost:3000/dmitry-s-babushkas/items` we want to see the items**

Make the store index have a list of links to each store ... go to the stores/index.html.erb
```
<div class="container">
  <% @stores.each do |store| %>
    <h1><%= link_to store.name, store_items_path(store: store.url) %></h1>
  <% end %>
</div>
```

Now they're links but we get "The action 'index' could not be found for Stores::ItemsController"

In `stores/items_controller.rb`
```
class Stores::ItemsController < ApplicationController
  def index
    store = Store.find_by(url: params[:store]) # find the store
    @items = store.items # get the items from the store
  end
end
```

 ... for this to work, we need to create the relationship between store and items

in `store.rb`
`has_many :items`

in `item.rb`
`belongs_to :store`

Make a migrations: (bad way is ....)  `rails g migration AddStoreIdToItems store:integer`  ... It's actually better to do `rails g migration AddStoreIdToItems store:references`
bcuz it's more performant.
`rake db:migrate`

Add itmes:
`rails c`
`store = Store.first`
`store.items << Item.first(10)` ... add the first 10 items to marla's store

Now we need a template to display the items:

`touch app/views/stores/items/index.html.erb`

and add ...
```
<div class="container">
  <div class="row">
    <div class="col-sm-12">
      <h1><%= @items.count %> Items</h1>
    </div>
  </div>
  <div class="row"></div>
  <% @items.each do |item| %>
    <div class="col-sm-3">
      <h5><%= item.name %></h5>
      <%= link_to(image_tag(item.image_url), item_path(item)) %>
      <p>
        <%= item.description %>
      </p>
    </div>
  <% end %>
</div>
```

Add items to Dmitry's store, too. Add the last 10 items, the same way we added the first 10 to Marla's store.

View a particular item for a store...
`stores/items_controller.rb`
```
  def show
    store = Store.find_by(url: params[:store])
    @item = store.items.find(params[:id])
  end
```

`touch app/views/stores/items/show.html.erb` and add ...
```
<div class="container">
  <div class="row"></div>
  <div class="col-sm-3">
    <h5><%= @item.name %></h5>
    <%= image_tag(@item.image_url) %>
    <p>
      <%= @item.description %>
    </p>
  </div>
</div>
```

view: http://localhost:3000/dmitry-s-babushkas/items/500
and see that we've successfully nested that particular item within that store.

Handle the case when the item doesn't exist:
in `stores/items_controller.rb`
Add a redirect to `show` and change `find` to `find_by id` because `find` raises an exception and we need the compiler to move onto the redirect.
```
  def show
    store = Store.find_by(url: params[:store])
    @item = store.items.find_by(id: params[:id])

    redirect_to store_items_path(store: store.url), notice: "Item not found" unless @item
  end
```

**Refactor**
Extract into a private method, `current_store`
```
class Stores::ItemsController < ApplicationController
  def index
    @items = @current_store.items
  end

  def show
    @item = @current_store.items.find_by(id: params[:id])

    redirect_to store_items_path(store: store.url), notice: "Item not found" unless @item
  end

  private

  def current_store
    @current_store ||= Store.find_by(url: params[:store])
  end
end
```

**Create a Stores/Stores controller**
add a helper method and before action
```
class Stores::StoresController < ApplicationController
  before_action :store_not_found # check if store exists before trying to render a store

  helper_method :current_store

  def current_store
    @current_store ||= Store.find_by(url: params[:store])
  end

  def store_not_found
    redirect_to root_path if current_store.nil?
  end
end
```
Now if we go to localhost:3000/non-existent-store-name/items, we get redirected to the root path

# Class work

1. Create namespaced routes for orders
2. Add sotres/orders controller that iwll show all orders for that store and a single order for that store.
3. Add orders to store via the console.

# Dynamic Navbar

in `_navbar.html.erb` add a condition:
```
    <% if current_store %>
      <%= link_to current_store.name, store_items_path(store: current_store) %>
    <% else %>
      <a class="navbar-brand" href="/">Storedom</a>
    <% end %>
```

We need access to the `current_store`
move the following helper to the application controller and add a conditional at the end ...
```
helper_method :current_store

  def current_store
    @current_store ||= Store.find_by(url: params[:store]) if params[:store]
  end
```

# Recap:

1. Multitenancy is better than installing code on servers locally
2. We turned a site into a Multitenancy store (Storedom was the example we used)
3. We modified the router using namespeces.
4. We added controllers
5. We mapped a new model, using callbacks to cleanup the URL
