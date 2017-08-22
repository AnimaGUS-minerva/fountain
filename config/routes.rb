Rails.application.routes.draw do
  resources :device_types
  resources :manufacturers
  resources :nodes

  resources :certificates do
    as_routes
  end

  # EST processing at well known URLs
  post '/.well-known/est/requestvoucher', to: 'est#voucherrequest'
end
