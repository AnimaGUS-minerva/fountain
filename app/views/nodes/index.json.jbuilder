json.array!(@nodes) do |node|
  json.extract! node, :id, :name, :fqdn, :eui64, :device_type_id, :manufacturer_id, :idevid
  json.url node_url(node, format: :json)
end
