class AddStatusToVoucherRequests < ActiveRecord::Migration[5.2]
  def change
    add_column :voucher_requests, :status, :json
  end
end
