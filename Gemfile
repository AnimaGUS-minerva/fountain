# coding: utf-8
source 'https://rubygems.org'

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', "~> 5.2.4.3"

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem "turbolinks"

#gem 'ecdsa',   :path => '../minerva/ruby_ecdsa'
gem 'ecdsa',   :git => 'https://github.com/AnimaGUS-minerva/ruby_ecdsa.git', :branch => 'ecdsa_interface_openssl'

#gem 'chariwt', :path => '../chariwt'
gem 'chariwt', :git => 'https://github.com/AnimaGUS-minerva/ChariWTs.git', :branch => 'v0.8.0'
gem 'jwt'

#gem "fixture_save", :path => "../fixture_save"
gem 'fixture_save', :git => 'https://github.com/mcr/fixture_save.git'

gem 'jbuilder', '~> 2.0'
gem 'rake', ">= 12.3.3"

#gem 'uglifier'
gem 'tzinfo-data'

gem 'mail'
gem 'ffi', '~> 1.10.0'
gem 'bundler', '>= 2.0.1'

# due to alerts
gem "yard", ">= 0.9.20"
gem "websocket-extensions", ">= 0.1.5"
gem "rack", ">= 2.1.4"
gem "loofah", ">= 2.3.1"
gem "activerecord", ">= 5.2.4.5"
gem "nokogiri", ">= 1.11.0"
gem "json", ">= 2.3.0"
gem "rexml", ">= 3.2.5"

# Use Capistrano for deployment
gem 'capistrano', '~> 3.11.0', group: :development
gem 'capistrano-rails',  group: :development
gem 'capistrano-rvm',    group: :development
gem 'capistrano-bundler',group: :development

#gem 'openssl', "~> 2.1.0"
gem 'openssl', :path => "../minerva/ruby-openssl"
#gem 'openssl', :path => '/gems/highway/ruby-openssl'
#gem 'openssl', :git => 'https://github.com/CIRALabs/ruby-openssl.git', :branch => 'ies-cms-dtls'

# CoAP server for Rails.
gem 'coap',    :git => 'https://github.com/AnimaGUS-minerva/coap.git', :branch => 'dtls-client'
#gem 'coap',    :path => "../minerva/coap"

gem 'celluloid-io', :git => 'https://github.com/AnimaGUS-minerva/celluloid-io.git', :submodules => true
#gem 'celluloid-io', :path => "../minerva/celluloid-io"

gem 'david', :git => 'https://github.com/AnimaGUS-minerva/david.git'
#gem 'david', :path => "../minerva/david"

# use this to get full decoding of HTTP Accept: headers, to be able to
# split off smime-type=voucher in pkcs7-mime, and other parameters
gem 'http-accept'

# IP address management for use in ANIMA ACP
gem 'ipaddress'

# encode/decode cbor messages
gem 'cbor'
gem 'rabl'
gem 'oj'

gem 'sqlite3', "~> 1.3.6"
gem 'pg', '~> 0.21'

# used in production on SecureHomeGateway
gem 'thin'
gem 'byebug'

# use for background processing of mud files, and interaction with
# mud-controller.
gem 'sucker_punch'
gem 'rb-readline'

group :development, :test do
  gem 'therubyracer', platforms: :ruby
  gem 'pry'
  gem 'pry-doc'

  #
  gem 'rspec-rails'
  gem 'rails-controller-testing'
  gem 'cbor-diag'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> in views
  #gem 'web-console', '~> 2.0'

  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'webmock'

  gem 'sprockets', "~> 3.7.2"

end

