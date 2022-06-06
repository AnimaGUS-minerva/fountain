class AddCertificateTypeToManufacturer < ActiveRecord::Migration[5.2]
  def change
    add_column :manufacturers, :certtype, :string
  end
end
