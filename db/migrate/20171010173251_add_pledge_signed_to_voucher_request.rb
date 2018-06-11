class AddPledgeSignedToVoucherRequest < ActiveRecord::Migration[4.2]
  def change
    add_column :voucher_requests, :pledge_request, :binary
  end
end
