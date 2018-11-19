# Load the Rails application.
require File.expand_path('../application', __FILE__)

# Initialize the Rails application.
Rails.application.initialize!

$VERSION = "0.5"
$ADMININTERFACE = false

# gets overritten by config/initializers/revision.rb by capistrano
$REVISION= "devel"

Mime::Type.register "application/voucher-cose+cbor", :vcc
Mime::Type.register "application/pkcs7-mime", :cms
Mime::Type.register "application/cms",        :cms

