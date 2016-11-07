class DeviceType < ActiveRecord::Base
  has_many :nodes
end
