# ssl-cert-tools
Helper tools to drive cfssl for CA, certs, and OpenVPN

## Purpose

This package helps with the auto-generation of SSL certificates.  It
also can create OpenVPN configurations for clients.

It does the following:

* Create CA keys and certificates
* Generates Diffie Hellman params
* Generates Server Certs
* Generates Client Cert
* Generates OpenVPN Peer Certs
  ** Creates OpenVPN config files with certs inline for easy distribute

It outputs CA related files to ./ca, and the various certificates
under the ./certs directory.

## Install the prereqs

The pre-reqs are openssl, jq, j2cli, and cfssl.

* If on Linux, ao a `make hostdeps`.
* Or install manually on you can probably install most of this with https://brew.sh/

## How to use it

* Edit the Makefile to set the quantities of each cert to generate
* Create or link to an existing configuration
  * Create a new config under ./conf/config.yaml.<your_config>
  * Then create a link `ln -s ./config/config.yaml.<your_config> ./config.yaml`
  * Edit that configuration ./config.yaml
* Make everything `make`
