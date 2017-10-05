class VouchersController < ApplicationController
  active_scaffold :voucher do |config|
    #config.columns = [ :eui64, :customer, :hostname ]
  end
end
