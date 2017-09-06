# -*- ruby -*-

namespace :fountain do

  # generate a signed voucher request with the pinned-domain-cert filled in
  # and send it to the appropriate MASA
  desc "send signed voucher request VRID=xx to optional MASA=url"
  task :send_voucher_request => :environment do
    vrid = ENV['VRID'].try(:to_i)
    masaurl = ENV['MASA']
    masa_id = ENV['MASAID'].try(:to_i)

    vr = VoucherRequest.find(vrid)
    unless vr.manufacturer.present?
      manu = Manufacturer.find(masa_id)
    else
      manu = vr.manufacturer
    end

    if manu
      target_url = manu.masaurl
    end
    if masaurl
      target_url = masaurl
    end

    signed_vr_json = vr.registrar_voucher_request_json

  end

end
