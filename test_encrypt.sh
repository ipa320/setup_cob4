#!/bin/sh
TOKEN="secret" # use Personal Access Token here
echo "TOKEN: $TOKEN"
ENCRYPT=$(echo "$TOKEN" | openssl enc -aes-256-cbc -salt -a -md md5 -pbkdf2)
echo "ENCRYPT: $ENCRYPT"
DECRYPT=$(echo "$ENCRYPT" | openssl enc -d -aes-256-cbc -salt -a -md md5 -pbkdf2)
echo "DECRYPT: $DECRYPT"
