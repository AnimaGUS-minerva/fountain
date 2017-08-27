class Manufacturer < ApplicationRecord
  has_many :nodes
  has_many :voucher_requests
end
