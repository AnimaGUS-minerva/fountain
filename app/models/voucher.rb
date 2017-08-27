class Voucher < ActiveRecord::Base
  belongs_to :manufacturer
  belongs_to :node
  belongs_to :voucher_request
end
