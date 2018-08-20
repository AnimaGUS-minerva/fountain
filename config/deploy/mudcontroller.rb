# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

server "mud-controller", user: "mud", roles: %{app db web}

set :rvm_ruby_string, "2.4.1"

