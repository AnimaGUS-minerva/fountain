# points to https://highway.sandelman.ca
def clientcert
  @clientcert ||= IO.binread("spec/files/product/081196FFFE0181E0/device.crt")
end

# fixture "device 12" (vizsla) in highway spec
# points to https://highway-test.sandelman.ca:9443
def cbor_clientcert_02
  @cbor_clientcert ||= IO.binread("spec/files/product/00-D0-E5-F2-00-02/device.crt")
end

# fixture "device 14"
# points to https://highway-test.sandelman.ca:9443
def cbor_clientcert_03
  @cbor_clientcert ||= IO.binread("spec/files/product/00-D0-E5-F2-00-03/device.crt")
end

# points to https://highway-test.sandelman.ca
def cbor_highwaytest_clientcert
  @cbor_highwaytest_clientcert ||= IO.binread("spec/files/product/00-D0-E5-E0-00-0F/device.crt")
end

# points to https://highway-test.sandelman.ca, which is manufacturer #7
def highwaytest_clientcert
  @highwaytest_clientcert ||= IO.binread("spec/files/product/00-D0-E5-F2-00-03/device.crt")
end
def highwaytest_masacert
  @highwaytest_masacert   ||= OpenSSL::X509::Certificate.new(IO.binread("spec/files/product/00-D0-E5-F2-00-03/masa.crt"))
end

# points to https://masa.honeydukes.sandelman.ca,
# devices fixture :bulb1, private key can be found in the reach project
def honeydukes_bulb1
  cert1_24
end

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

def smarkaklink_client_1502
  @smarkaklink_client_01 ||= IO.binread("spec/files/product/Smarkaklink-1502449999/ldevice.crt")
end

def florean03_clientcert
  @florean03_clientcert ||= OpenSSL::X509::Certificate.new(IO.binread("spec/files/product/00-D0-E5-03-00-03/device.crt"))
end
