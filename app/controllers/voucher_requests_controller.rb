class VoucherRequestsController < AdminController
  active_scaffold :voucher_request do |config|
    #config.columns = [ :eui64, :customer, :hostname ]
  end
end
