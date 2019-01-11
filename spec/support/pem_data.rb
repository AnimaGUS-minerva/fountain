# 00-D0-E5-02-00-20 is signed by manufacturer #2 (honeydukes)
def cert1
  @cert1 ||= OpenSSL::X509::Certificate.new(File.read("spec/certs/00-D0-E5-02-00-20.crt"))
end

# 00-D0-E5-02-00-1B is signed by manufacturer #2 (honeydukes), but has no fixture
def cert2
  @cert2 ||= OpenSSL::X509::Certificate.new(File.read("spec/files/product_00-D0-E5-02-00-1B/device.crt"))
end

