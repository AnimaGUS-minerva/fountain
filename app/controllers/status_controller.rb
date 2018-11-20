class StatusController < ApiController
  include ActionController::MimeResponds

  def index
    @stats = [['Devices', Certificate.count],
              ['Vouchers',Voucher.count],
              ['Requests',VoucherRequest.count],
             ]
    respond_to do |format|
      format.html {
        render layout: 'reload'
      }
      format.json {
        data = Hash.new
        @stats.each { |n| data[n[0]]=n[1] }
        api_response(data, :ok, 'application/json')
      }
    end
  end
end
