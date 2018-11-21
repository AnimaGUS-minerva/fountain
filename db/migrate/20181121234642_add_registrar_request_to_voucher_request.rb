class AddRegistrarRequestToVoucherRequest < ActiveRecord::Migration[5.2]
  def change
    add_column :voucher_requests, :registrar_request, :binary
  end
end
