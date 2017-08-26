class EstController < ApplicationController

  # GET /.well-known/est/requestvoucher
  def requestvoucher
    @voucherreq = VoucherRequest.from_json_jose(request.body.read, params)

    clientcert_pem = request.env["SSL_CLIENT_CERT"]
    if clientcert_pem
      @voucherreq.tls_clientcert = clientcert_pem
    end
    @voucherreq.save!

    head :ok
  end


  private

end
