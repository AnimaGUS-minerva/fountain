# server-based syntax
# ======================
# Defines a single server with a list of roles and multiple properties.
# You can define all roles on a single server, or split them:

server "malkin", user: "fountain", roles: %{app db web}

#before 'deploy:setup', 'rvm:install_rvm'  # install/update RVM
#before 'deploy:setup', 'rvm:install_ruby' # install Ruby and create gemset, OR:

set :rvm_custom_path, '/usr/share/rvm'
set :rvm_type, :system
set :rvm_ruby_version, '2.6.3'

