class Manufacturer < ApplicationRecord
  has_many :nodes
  has_many :voucher_requests

  def self.trusted_client_by_pem(clientpem)
    false
  end
end
