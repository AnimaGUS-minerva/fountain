class EstController < ApplicationController

  # GET /.well-known/est/requestvoucher

  def voucherrequest
    head :ok
  end


  private

end
