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

countryName="/C=CA"
stateOrProvinceName="/ST=Ontario"
localityName="/L=Almonte"
organizationName="/O=Fire Department"
#organizationalUnitName="/OU="
organizationalUnitName=
commonName="/CN=Root CA"
DN=$countryName$stateOrProvinceName$localityName
DN=$DN$organizationName$organizationalUnitName$commonName
echo $DN
export subjectAltName=email:postmaster@unknownca.example.com
export default_crl_days=2048
