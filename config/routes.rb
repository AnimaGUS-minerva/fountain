Rails.application.routes.draw do
  if $ADMININTERFACE or Rails.env == 'test'
    concern :active_scaffold
    concern :active_scaffold_association, ActiveScaffold::Routing::Association.new
    concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)

    resources :vouchers, concerts: :active_scaffold
    resources :voucher_requests, concerts: :active_scaffold
    resources :device_types, concerts: :active_scaffold
    resources :manufacturers, concerts: :active_scaffold
    resources :nodes, concerts: :active_scaffold
    resources :certificates, concerts: :active_scaffold
  end

  # EST processing at well known URLs
  post '/.well-known/est/requestvoucher', to: 'est#requestvoucher'
  post '/.well-known/est/voucher_status', to: 'est#voucher_status'

  if true # was $COAPSERVER, but it does not get set early enough.
    #get '/.well-known/core',   to: 'core#index'
    post '/e/rv', to: 'est#requestvoucher', coap: true, rt: 'ace.est', short: '/e'
    post '/e/vs', to: 'est#voucher_status', coap: true, rt: 'ace.est', short: '/e'
  end

  #
end
