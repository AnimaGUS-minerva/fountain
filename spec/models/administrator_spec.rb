require 'rails_helper'

RSpec.describe Administrator, type: :model do
  fixtures :all

  it "should have an admin bit" do
    admin1 = administrators(:admin1)
    expect(admin1.admin).to   be true
    expect(admin1.enabled).to be true
    expect(admin1.prospective).to be false
  end

  it "should have a certificate" do
    admin1 = administrators(:admin1)
    expect(admin1.certificate).to_not be_nil
    expect(admin1.certificate.subject.to_s).to eq("/DC=ca/DC=sandelman/CN=administrator")
  end

  it "should have default values" do
    n1 = Administrator.create
    expect(n1.enabled).to     be false
    expect(n1.admin).to       be false
    expect(n1.prospective).to be true
  end

  it "should find admins by public DER encoded key" do
    admin1 = administrators(:admin1)
    cert =  OpenSSL::X509::Certificate.new(admin1.public_key)
    expect(Administrator.find_by_cert(cert)).to_not be_nil
  end

  it "should find admins by public PEM encoded key" do
    admin1 = administrators(:admin1)
    cert =  OpenSSL::X509::Certificate.new(admin1.public_key)
    admin1.public_key = cert.to_pem
    admin1.save
    expect(Administrator.find_by_cert(cert)).to_not be_nil
  end

end
