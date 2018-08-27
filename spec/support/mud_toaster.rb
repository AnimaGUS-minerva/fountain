def get_stub(url, result, ct)

  voucher_request = nil
  up = URI.parse(url)

  stub_request(:get, url).
    with(headers: {
           'Accept'          => '*/*',
           'Accept-Encoding' => 'gzip;q=1.0,deflate;q=0.6,identity;q=0.3',
           'User-Agent'      => 'Ruby'
         }).
    to_return(status: 200, body: lambda { |request|
                voucher_request = request.body
                result},
              headers: {
                'Content-Type'=> ct
              })

end

def mud1_stub(url, filename = nil)
  result = ""
  if filename
    result = File.read(filename)
  end

  get_stub(url, result, 'application/mud+json')
end

def mud1_stub_sig(url, filename = nil)
  result   = ""
  if filename
    result = File.read(filename)
  end

  get_stub(url, result, 'application/pkcs7-signature')
end

