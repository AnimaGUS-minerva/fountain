class AddIssuerDnToManufacturer < ActiveRecord::Migration[5.2]
  def change
    add_column :manufacturers, :issuer_dn, :text
  end
end
