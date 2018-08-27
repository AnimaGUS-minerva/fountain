require 'open-uri'

class DeviceType < ActiveRecord::Base
  has_many :devices
  belongs_to :manufacturer

  def self.find_or_create_by_mud_url(mu)
    dt = find_by_mud_url(mu)
    unless dt
      dt = create(:mud_url => mu)
    end

    dt.validate_mud_url
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
    attributes[:mud_url_sig] || build_sig_url
  end

  def validate_mud_url
    open(mud_url_sig) { |f|
      signature = f.read
    }

  end

  def mud_json
    unless @mud_json.kind_of? Hash
      open(mud_url) {|f|
        self.mud_json = JSON::parse(f.read)
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
