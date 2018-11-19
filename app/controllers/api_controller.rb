class ApiController < ActionController::Metal
  include AbstractController::Rendering
  include ActionController::Renderers::All
  include ActionController::Head
  include ActionController::Redirecting
  include ActionController::DataStreaming
  include Rails.application.routes.url_helpers
  include Response

  def logger
    ActionController::Base.logger
  end
end

