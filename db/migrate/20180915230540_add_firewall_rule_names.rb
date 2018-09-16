class AddFirewallRuleNames < ActiveRecord::Migration[5.2]
  def change
    change_table :devices do |t|
      # would prefer to use JSON, and have arrays, but sqlite3 does not
      # support JSON.
      t.json    :firewall_rule_names
      t.boolean :deleted
      t.boolean :quaranteed
      t.boolean :device_enabled
    end
  end
end
