$ADMININTERFACE ||= ENV['ADMININTERFACE']

Rails.application.routes.draw do
  resources :administrators
  resources :devices

  if $ADMININTERFACE or Rails.env == 'test'
    concern :active_scaffold
    concern :active_scaffold_association, ActiveScaffold::Routing::Association.new
    concern :active_scaffold, ActiveScaffold::Routing::Basic.new(association: true)

    resources :vouchers,         concerns: :active_scaffold
    resources :voucher_requests, concerns: :active_scaffold
    resources :device_types,     concerns: :active_scaffold
    resources :manufacturers,    concerns: :active_scaffold
    resources :certificates,     concerns: :active_scaffold
  end

  # EST processing at well known URLs
  post '/.well-known/est/requestvoucher', to: 'est#requestvoucher'
  post '/.well-known/est/voucher_status', to: 'est#voucher_status'
  get  '/.well-known/est/cacerts',        to: 'est#cacerts'
  get  '/.well-known/est/csrattributes',  to: 'est#csrattributes'

  if true # was $COAPSERVER, but it does not get set early enough.
    #get '/.well-known/core',   to: 'core#index'
    post '/e/rv', to: 'est#cbor_rv', coap: true, rt: 'ace.est', short: '/e'
    post '/e/vs', to: 'est#cbor_vs', coap: true, rt: 'ace.est', short: '/e'

    # get /cacerts
    get '/e/crts', to: 'est#cbor_crts', coap: true, rt: 'ace.est', short: '/e'

    # get /att
    get  '/.well-known/est/att', to: 'est#cbor_crts', coap: true, rt: 'ace.est', short: '/e'
    get '/e/att',  to: 'est#cbor_crts', coap: true, rt: 'ace.est', short: '/e'
  end

  resources :status,  :only => [:index ]
  resources :version, :only => [:index ]

end
