class AddTlsClientcertToVoucherRequest < ActiveRecord::Migration
  def change
    add_column :voucher_requests, :tls_clientcert, :text
  end
end
