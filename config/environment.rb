# Load the Rails application.
require File.expand_path('../application', __FILE__)

Rails.application.config.active_record.sqlite3.represent_boolean_as_integer = true

# Initialize the Rails application.
Rails.application.initialize!

