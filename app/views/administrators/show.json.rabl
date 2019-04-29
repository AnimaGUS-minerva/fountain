# -*- ruby -*-
#
object @object
attributes :public_key, :id, :name, :admin, :enabled, :prospective, :created_at, :updated_at
node :public_key do |u|
  u.certificate_pem
end
