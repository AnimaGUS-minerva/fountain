# coding: utf-8
source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', "~> 5.1"

# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'

# Use jquery as the JavaScript library
gem 'jquery-rails'

# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem "turbolinks"

#gem 'ecdsa',   :path => '../minerva/ruby_ecdsa'
gem 'ecdsa',   :git => 'https://github.com/AnimaGUS-minerva/ruby_ecdsa.git', :branch => 'ecdsa_interface_openssl'

#gem 'chariwt', :path => '../chariwt'
gem 'chariwt', :git => 'https://github.com/mcr/ChariWTs.git', :branch => 'v0.6.0'
gem 'jwt'

#gem "fixture_save", :path => "../fixture_save"
gem 'fixture_save', :git => 'https://github.com/mcr/fixture_save.git'

gem 'active_scaffold',  :git => "https://github.com/mcr/active_scaffold.git"
#gem 'active_scaffold', :git => "https://github.com/activescaffold/active_scaffold.git", :branch => 'master'

gem 'jbuilder', '~> 2.0'
gem 'rake'

gem 'sdoc', '~> 0.4.0'
gem 'uglifier'

gem 'mail'
gem 'ffi', '~> 1.9.24'

# Use Capistrano for deployment
gem 'capistrano', '~> 3.11.0', group: :development
gem 'capistrano-rails',  group: :development
gem 'capistrano-rvm',    group: :development
gem 'capistrano-bundler',group: :development

#gem 'openssl', "~> 2.1.0"
gem 'openssl', :path => "../minerva/ruby-openssl"

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
gem 'json'
gem 'rabl'
gem 'oj'

gem 'sqlite3'
gem 'pg', '0.20'

# used in production on SecureHomeGateway
gem 'thin'
gem 'byebug'

# use for background processing of mud files, and interaction with
# mud-controller.
gem 'sucker_punch'

group :development, :test do
  gem 'therubyracer', platforms: :ruby
  gem 'pry'
  gem 'pry-doc'

  #
  gem 'rspec-rails', '~> 3.0'
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

