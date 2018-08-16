class AddMudInfoToNode < ActiveRecord::Migration[5.2]
  def change
    change_table :nodes do |t|
      t.json    :traffic_counts
      t.text    :mud_url
      t.integer :profile_id
      t.text    :current_vlan
      t.boolean :wan_enabled
      t.boolean :lan_enabled
      t.json    :firewall_rules
    end
  end
end
