class Manufacturer < ApplicationRecord
  has_many :devices
  has_many :voucher_requests
  has_many :device_types
end
