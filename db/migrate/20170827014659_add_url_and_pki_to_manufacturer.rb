class AddUrlAndPkiToManufacturer < ActiveRecord::Migration[4.2]
  def change
    add_column :manufacturers, :masa_url, :text
    add_column :manufacturers, :issuer_public_key, :binary
  end
end
