class DeviceType < ActiveRecord::Base
  has_many :devices
  belongs_to :manufacturer
end
