# -*- ruby -*-
#
object @object
attributes :public_key, :id, :name, :admin, :enabled, :prospective
node :public_key do |u|
  u.certificate_pem
end
