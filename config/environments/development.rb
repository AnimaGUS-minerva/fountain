require 'mock_mud_socket'

Rails.application.configure do
  # Settings specified here will take precedence over those in config/application.rb.

  # In the development environment your application's code is reloaded on
  # every request. This slows down response time but is perfect for development
  # since you don't have to restart the web server when you make code changes.
  config.cache_classes = false

  # Do not eager load code on boot.
  config.eager_load = true

  # Show full error reports and disable caching.
  config.consider_all_requests_local       = true
  config.action_controller.perform_caching = false

  # Don't care if the mailer can't send.
  config.action_mailer.raise_delivery_errors = false

  # Print deprecation notices to the Rails logger.
  config.active_support.deprecation = :log

  # Raise an error on page load if there are pending migrations.
  config.active_record.migration_error = :page_load

  # Raises error for missing translations
  # config.action_view.raise_on_missing_translations = true

  config.hosts = [
    IPAddr.new("0.0.0.0/0"), # All IPv4 addresses.
    IPAddr.new("::/0"),      # All IPv6 addresses.
    "localhost",              # The localhost reserved domain.
    "fountain-test.example.com"   # The test hostname
  ]

  # setup the MockMudSocket, this will overide the parent,
  # and mock out the environment environment.
  MockMudSocket.new(nil, "tmp/devel_mud_super.tout")
end

Rabl.configure do |config|
  config.raise_on_missing_attribute = true

end

$MUD_TMPDIR_PUBLIC = "/tmp/mudfiles"
$MUD_TMPDIR        = "/tmp/mudfiles"

# in development mode, use the canned certificates from spec/files/cert,
# which are also used for test.

$ENABLE_TOFU = true
