#!/usr/bin/env bash
#
# Original file at: https://raw.githubusercontent.com/IPNetworkingLab/BGPoST-Artifacts/refs/heads/main/cert-generator/generate_certs.sh

set -e

if [ "$#" != "5" ]; then
  echo "This script takes 5 args."
  echo "$0 <dest_dir> <certificate_name> <pkey alg> <dns_name> <ip>"
  echo "   <dest_dir>: directory where certificate will be stored"
  echo "   <certificate_name>: prefix of the name (the suffixes .key,"
  echo "                       .csr, .cert.pem) will be automatically"
  echo "                       added by the script"
  echo "   <pkey alg>: either ED25519 or RSA"
  echo "   <dns_name>: certificate CN field"
  echo "   <ip>: IP address of the server on which the certificate"
  echo "         will be used"
  exit 1
fi

DEST_DIR=$1
NAME=$2
PKEY_ALG=$3
COMMON_NAME=$4
ALT_NAME_IP=$5
PKEY_ALG_OPT=""

CA_KEY="$DEST_DIR"/ca.key
CA_CRT="$DEST_DIR"/ca.cert.pem
CA_CFG_FILE="$(mktemp)"

RTR_KEY="$DEST_DIR"/"$NAME"/router.key
RTR_CSR="$DEST_DIR"/"$NAME"/router.csr
RTR_CRT="$DEST_DIR"/"$NAME"/router.cert.pem
RTR_CFG="$(mktemp)"

# CONFIG for V3_EXT
V3_EXT="$(mktemp)"

algo_check() {
  if [ "$1" = "RSA" ]; then
    PKEY_ALG_OPT+=" -pkeyopt rsa_keygen_bits:8192"
  elif [ "$1" = "ED25519" ]; then
    PKEY_ALG_OPT+=""
  else
    echo "Unknown algorithm. Got \"$1\". Expected \"RSA\" or \"ED25519\" (Names are case sensitive)"
    exit 1
  fi
}

# 0. First check algo
algo_check "$PKEY_ALG"

cat <<EOF > "$V3_EXT"
nsCertType = server, client
subjectKeyIdentifier = hash
basicConstraints = CA:FALSE
keyUsage = critical, digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth, clientAuth
subjectAltName = @alt_names
EOF

cat <<EOF >> "$V3_EXT"
[alt_names]
DNS.1 = $COMMON_NAME
DNS.2 = www.$COMMON_NAME
IP.1 = $ALT_NAME_IP
EOF

# Config for root CA
cat <<EOF > "$CA_CFG_FILE"
[ req ]
# Extension to add when the -x509 option is used.
x509_extensions     = v3_ca
distinguished_name  = req_distinguished_name
prompt = no

[ req_distinguished_name ]
countryName         = BE
stateOrProvinceName = "Brabant Wallon"
localityName        = "Louvain-la-Neuve"
organizationName    = "IP Networking Lab"
commonName          = "Router Root CA"

[ v3_ca ]
# Extensions for a typical CA (man x509v3_config).
subjectKeyIdentifier = hash
authorityKeyIdentifier = keyid:always,issuer
basicConstraints = critical, CA:true
keyUsage = critical, digitalSignature, cRLSign, keyCertSign
EOF


# Config for Router Certificate
cat <<EOF > "$RTR_CFG"
[req]
distinguished_name = dn
prompt=no
req_extensions=req_ext

[dn]
C="BE"
ST="Brabant wallon"
O="Université catholique de Louvain"
CN="$COMMON_NAME"

[req_ext]
$(cat "$V3_EXT")
EOF

if [ ! -f "$CA_KEY" ]; then
  echo "No Root CA, generating one..."
  #1. Generate CA pkey
  openssl genpkey -algorithm "$PKEY_ALG" $PKEY_ALG_OPT > "$CA_KEY"
  #2. Generate Root CA
  openssl req -new -x509 -days 365 -key "$CA_KEY" -out "$CA_CRT" -config "$CA_CFG_FILE"
fi

cp "$CA_CRT" "$DEST_DIR/$NAME"

#3. Generate rtr server key
openssl genpkey -algorithm "$PKEY_ALG" $PKEY_ALG_OPT > "$RTR_KEY"

#4. Generate signing request for rtr certificate
openssl req -new -key "$RTR_KEY" -out "$RTR_CSR" -config "$RTR_CFG"

#5. Sign rtr certificate with CA
openssl x509 -req -days 365 -in "$RTR_CSR" -CA "$CA_CRT" -CAkey "$CA_KEY" \
             -CAcreateserial -out "$RTR_CRT" -extfile "$V3_EXT"

#### Optionally verify crt
#openssl x509 -noout -text -in "$RTR_CRT"

# Clean our mess
rm "$CA_CFG_FILE" "$RTR_CFG" "$RTR_CSR" "$V3_EXT"
