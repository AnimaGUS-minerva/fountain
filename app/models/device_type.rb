require 'open-uri'
require 'digest'

class DeviceType < ActiveRecord::Base
  has_many :devices
  belongs_to :manufacturer

  attr_accessor :raw_json

  def self.find_or_create_by_mud_url(mu)
    dt = find_by_mud_url(mu)
    unless dt
      dt = create(:mud_url => mu)
    end

    dt.validate_mud_url
    dt.save!
    dt
  end

  def mud_uri
    @umu ||= URI.parse(mud_url)
  end

  def build_sig_url
    rsig = mud_json_ietf["mud-signature"]
    self.mud_url_sig = URI.join(mud_uri, rsig).to_s
  end
  def mud_url_sig
    self[:mud_url_sig] || build_sig_url
  end

  def validate_mud_url
    signature = nil
    open(mud_url_sig) { |f|
      signature = f.read
    }

    # empty certificate store.
    cert_store    = OpenSSL::X509::Store.new
    pkcs7activity = OpenSSL::PKCS7.new(signature)
    certlist      = []
    certs         = pkcs7activity.certificates
    if certs
      sign0         = certs.first
      certlist      = [sign0]
    end

    # do not attempt to validate the certificates.
    flags         = OpenSSL::PKCS7::NOCHAIN|OpenSSL::PKCS7::NOVERIFY
    result        = pkcs7activity.verify(certlist, cert_store, raw_json, flags)

    # find manufacturer by signer of mudfile.
    if result
      self.validated_mud_json = mud_json
    end
    # do something if result == false?  raise exception?

    result
  end

  def mud_json
    unless @mud_json.kind_of? Hash
      open(mud_url) {|f|
        @raw_json = f.read
        self.mud_json = JSON::parse(@raw_json)
      }
    end
    @mud_json
  end
  def mud_json=(x)
    @mud_json = x
  end

  def mud_json_ietf
    mud_json["ietf-mud:mud"]
  end
end
