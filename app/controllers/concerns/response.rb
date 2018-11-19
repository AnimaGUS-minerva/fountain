# app/controllers/concerns/response.rb
module Response
  def api_response(object, status = :ok, content = nil)
    render json: object, status: status, content_type: content
  end
  def raw_response(object, status = :ok, content = nil)
    send_data object, :type => content
  end
end
