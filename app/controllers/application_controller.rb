class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  # David (COAP server), adds discoverable option
  unless self.respond_to?(:discoverable)
    def self.discoverable(options)
      # true
    end
  end

end
