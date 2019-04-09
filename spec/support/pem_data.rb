# 00-D0-E5-02-00-24 is signed by manufacturer #2 (honeydukes)
def cert1_24
  @cert1 ||= OpenSSL::X509::Certificate.new(File.read("spec/files/product/00-D0-E5-02-00-24/device.crt"))
end

# 00-D0-E5-02-00-1B is signed by manufacturer #2 (honeydukes), but has no fixture for cert
def cert2_1B
  @cert2 ||= OpenSSL::X509::Certificate.new(File.read("spec/files/product/00-D0-E5-02-00-1B/device.crt"))
end

# 00-D0-E5-01-00-0B is signed by manufacturer #3 (wheezes), but has no fixture
# it has a MASA URL that points to https://wheezes.honeydukes.sandelman.ca
# the manufactuer is marked as a administratively trusted.
def wheezes_bulb03
  @cert3 ||= OpenSSL::X509::Certificate.new(File.read("spec/files/product/00-D0-E5-01-00-0B/device.crt"))
end


