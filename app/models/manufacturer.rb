class Manufacturer < ApplicationRecord
  has_many :devices
  has_many :voucher_requests
  has_many :device_types

  enum trust: {
         unknown: "unknown",     # a new manufacturer, unknown trust.
         firstused: "firstuse",  # a new manufacturer, first time encountered.
         admin: "admin",         # manufacturer that was firstused, now blessed.
         brski: "brksi",         # manufacturer can be trusted if voucher obtained.
         webpki: "webpki"        # manufacturer can be trusted if MASA has valid WebPKI.
       },  _prefix: :trust

  def self.trusted_client_by_pem(clientpem)
    false
  end
end
