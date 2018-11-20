#
# it should be possible to simplify this further.
# the challenge is how to fill in the gaps appropriately.
# Things break in complicated fashions.
#
class ApiController < ActionController::Metal
  include Response

  ActionController::Base.without_modules(:ParamsWrapper,
                                         :Caching,
                                         :ParameterEncoding).each do |left|
    include left
  end
  abstract!
  setup_renderer!

  ActiveSupport.run_load_hooks(:action_controller_base, self)
  ActiveSupport.run_load_hooks(:action_controller, self)

  def logger
    ActionController::Base.logger
  end
end

