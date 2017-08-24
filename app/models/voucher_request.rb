class VoucherRequest < ApplicationRecord
  belongs_to :voucher
  belongs_to :owner
  belongs_to :device

  class InvalidVoucherRequest < Exception; end
  class MissingPublicKey < Exception; end

  def self.from_json_jose(token)
    json = Chariwt::VoucherRequest.from_json_jose(token)
    vr = create(details: json)
    vr.populate_explicit_fields
    vr.owner      = Owner.find_by_public_key(vr.vdetails["pinned-domain-cert"])
    vr
  end

  def vdetails
    raise VoucherRequest::InvalidVoucherRequest unless details["ietf-voucher:voucher"]
    @vdetails ||= details["ietf-voucher:voucher"]
  end

  def name
    "voucherreq_#{self.id}"
  end
  def savefixturefw(fw)
    voucher.savefixturefw(fw) if voucher
    owner.savefixturefw(fw)   if owner
    save_self_tofixture(fw)
  end

  def populate_explicit_fields
    self.device_identifier = vdetails["serial-number"]
    self.device            = Device.find_by_number(device_identifier)
    self.nonce             = vdetails["nonce"]
  end

  def issue_voucher
    # at a minimum, this must be before a device that belongs to us!
    return nil unless device

    # must have an owner!
    return nil unless owner

    # XXX if there is another valid voucher for this device, it must be for
    # the same owner.

    ## XXX what other kinds of validation belongs here?

    voucher = Voucher.create(owner: owner,
                             device: device,
                             nonce: nonce)
    unless nonce
      voucher.expires_on = Time.now + 14.days
    end
    voucher.jose_sign!
  end

end
