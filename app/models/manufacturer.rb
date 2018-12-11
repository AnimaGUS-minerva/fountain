class Manufacturer < ApplicationRecord
  has_many :devices
  has_many :voucher_requests
  has_many :device_types

  def self.trusted_client_by_pem(clientpem)
    false
  end
end
