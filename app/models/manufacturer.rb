class Manufacturer < ActiveRecord::Base
  has_many :nodes
  has_many :voucher_requests
end
