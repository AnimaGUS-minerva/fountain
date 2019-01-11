# 00-D0-E5-02-00-20 is signed by manufacturer #2.
def cert1
  @cert1 ||= OpenSSL::X509::Certificate.new(File.read("spec/certs/00-D0-E5-02-00-20.crt"))
end
