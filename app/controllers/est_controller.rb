class EstController < ApplicationController

  # GET /.well-known/est/requestvoucher
  def requestvoucher
    @voucherreq = VoucherRequest.from_json_jose(request.body.read)
    vr = params["ietf-voucher-request:voucher"]
    byebug

    head :ok
  end


  private

end
