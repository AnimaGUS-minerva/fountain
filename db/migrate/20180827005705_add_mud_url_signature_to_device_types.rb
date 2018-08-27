class AddMudUrlSignatureToDeviceTypes < ActiveRecord::Migration[5.2]
  def change
    add_column :device_types, :mud_url, :text
    add_column :device_types, :mud_url_sig, :text
    add_column :device_types, :validated_mud_json, :json
    add_column :device_types, :manufacturer_id, :integer
  end
end
