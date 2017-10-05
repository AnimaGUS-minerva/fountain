Rails.application.routes.draw do
  resources :vouchers do
    as_routes
  end
  resources :voucher_requests do
    as_routes
  end
  resources :device_types do
    as_routes
  end
  resources :manufacturers do
    as_routes
  end
  resources :nodes do
    as_routes
  end
  resources :certificates do
    as_routes
  end

  # EST processing at well known URLs
  post '/.well-known/est/requestvoucher', to: 'est#requestvoucher'
end
