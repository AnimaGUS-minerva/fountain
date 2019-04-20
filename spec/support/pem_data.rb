# 00-D0-E5-02-00-24 is signed by manufacturer #2 (honeydukes)
def cert1_24
  @cert1 ||= OpenSSL::X509::Certificate.new(File.read("spec/files/product/00-D0-E5-02-00-24/device.crt"))
end

# 00-D0-E5-02-00-1B is signed by manufacturer #2 (honeydukes), but has no fixture for cert
def cert2_1B
  @cert2 ||= OpenSSL::X509::Certificate.new(File.read("spec/files/product/00-D0-E5-02-00-1B/device.crt"))
end

# 00-D0-E5-01-00-0B is signed by manufacturer #3 (wheezes)
# it has a MASA URL that points to https://wheezes.honeydukes.sandelman.ca
# the manufactuer is marked as a administratively trusted in the fixture
def wheezes_bulb03
  @cert3 ||= OpenSSL::X509::Certificate.new(File.read("spec/files/product/00-D0-E5-01-00-0B/device.crt"))
end

# 00-D0-E5-F3-00-01 is signed by manufacturer borgin (within highway test data),
# but has no manufacturer fixture
# it has a MASA URL that points to https://borgin-test.example.com:9445
def borgin01
  @cert4 ||= OpenSSL::X509::Certificate.new(File.read("spec/files/product/00-D0-E5-F3-00-01/device.crt"))
end

# points to https://highway-test.sandelman.ca
# issuer has been added to manufacturers with "trust_brski", #4.
def highwaytest_clientcert_f20001
  @highwaytest_clientcert_f20001 ||= IO.binread("spec/files/product/00-D0-E5-F2-00-01/device.crt")
end


