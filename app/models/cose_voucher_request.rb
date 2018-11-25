class CoseVoucherRequest < VoucherRequest
  def cose_voucher_request?
    true
  end

  # create a voucher request (CBOR+COSE) appropriate for sending to the MASA.
  # it shall always be signed.
  def calc_registrar_voucher_request_cose
    # now build our voucher request from the one we got.
    vreq            = Chariwt::VoucherRequest.new(format: :cose_cbor)
    vreq.signing_cert = FountainKeys.ca.jrc_pub_key
    vreq.nonce      = nonce
    vreq.serialNumber = device_identifier
    vreq.createdOn  = created_at
    vreq.assertion  = :proximity
    vreq.coseSignedPriorVoucherRequest!
    vreq.priorSignedVoucherRequest = pledge_request
    self.request = vreq
    #puts "TMPKEY: #{$FAKED_TEMPORARY_KEY}"
    token = vreq.cose_sign(FountainKeys.ca.jrc_priv_key,
                           ECDSA::Group::Nistp256,
                           $FAKED_TEMPORARY_KEY)  # usually nil.
  end

  def details=(x)
    n = Hash.new
    x.each { |k,v|
      case k
      when "ietf-voucher-request:voucher"
        nn = Hash.new
        n[k] = nn
        v.each { |kk,vv|
          case kk
          when "proximity-registrar-cert"
            nn["base64_#{kk}"] = Base64.urlsafe_encode64(vv)
          else
            nn[kk] = vv
          end
        }
      end
    }
    self[:details] = n
  end
  def decode_details
    n = Hash.new
    self[:details].each { |k,v|
      case k
      when "ietf-voucher-request:voucher"
        nn = Hash.new
        n[k] = nn

        v.each { |kk,vv|
          case kk
          when "base64_proximity-registrar-cert"
            nn["proximity-registrar-cert"] = Base64.urlsafe_decode64(vv)
          else
            nn[kk] = vv
          end
        }
      end
    }
    n
  end
  def details
    @details ||= decode_details
  end

  def registrar_voucher_request
    @cose_voucher ||= calc_registrar_voucher_request_cose
  end

  def registrar_voucher_request_type
    'application/voucher-cose+cbor'
  end
  def registrar_voucher_desired_type
    'multipart/mixed'
  end

end
