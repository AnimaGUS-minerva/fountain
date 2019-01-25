
export dir=$cadir/intermediate
mkdir -p $dir
cd $dir
mkdir -p certs crl csr newcerts private
chmod 700 private
touch index.txt
sn=8 # hex 8 is minimum, 19 is maximum
echo 1000 > $dir/crlnumber

# cd $dir
export crlDP=
# For CRL support use uncomment these:
#crl=intermediate.crl.pem
#crlurl=www.htt-consult.com/pki/$crl
#export crlDP="URI:http://$crlurl"
export default_crl_days=30
export ocspIAI=
# For OCSP support use uncomment these:
#ocspurl=ocsp.htt-consult.com
#export ocspIAI="OCSP;URI:http://$ocspurl"

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

