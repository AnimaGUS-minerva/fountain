export dir=`pwd`
export cadir=`pwd`
export format=pem
mkdir -p $dir
cd $dir
mkdir -p certs crl csr newcerts private
chmod 700 private
touch index.txt
touch serial
sn=8

# this exactly matches the CA that is setup in highway/spec/files/cert
countryName="/DC=ca"
stateOrProvinceName="/DC=sandelman"
localityName=""
organizationName=""
#organizationalUnitName="/OU="
organizationalUnitName=
commonName="/CN=highway-test.example.com root CA"
DN=$countryName$stateOrProvinceName$localityName
DN=$DN$organizationName$organizationalUnitName$commonName
echo $DN
export subjectAltName=email:postmaster@unknownca.example.com
export default_crl_days=2048
