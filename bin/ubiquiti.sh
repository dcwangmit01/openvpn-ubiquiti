#!/bin/bash
set -ueo pipefail
set -x

USER=dave
UBIQUITY=192.168.10.1

CA_DIR=ca
CERTS_DIR=certs

MACHINE="${USER}@${UBIQUITY}"
KEY_DIR=/config/auth/keys

ssh $MACHINE mkdir -p $KEY_DIR
scp $CA_DIR/ca.pem $MACHINE:$KEY_DIR/ca.crt
scp $CERTS_DIR/server01-key.pem $MACHINE:$KEY_DIR/server.key
scp $CERTS_DIR/server01.pem $MACHINE:$KEY_DIR/server.crt
scp $CA_DIR/dh4096.pem $MACHINE:$KEY_DIR/dh4096.pem
scp $CA_DIR/ta.key $MACHINE:$KEY_DIR/ta.key


