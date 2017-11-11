class DeviceTypesController < AdminController
  active_scaffold :certificate do |config|
    #config.columns = [ :eui64, :customer, :hostname ]
  end
end
