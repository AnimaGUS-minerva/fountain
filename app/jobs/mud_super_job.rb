class MudSuperJob < ApplicationJob
  queue_as :default

  def perform(*args)
    deviceId = args.first
    device = Device.find(deviceId)

    # determine whether device is being added or deleted (this is idempotent)
    unless device.device_state_correct?
      device.switch_to_state!
    end
  end
end
