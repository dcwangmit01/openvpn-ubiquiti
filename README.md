# openvpn-ubiquity

## Purpose

This package helps with the auto-generation of SSL certificates and
configuration of OpenVPN on Ubiquity Edgeos Routers and OpenVPN
clients.  The cert generation parts of this package can be used to
automatically create a basic CA along with server, client, and peer
certificates for any use.

It does the following:

* Create CA keys and certificates
* Generates Diffie Hellman params
* Generates Server Certs
* Generates Client Cert
* Generates OpenVPN Peer Certs
  * Creates OpenVPN config files with certs inline for easy distribute

It outputs CA related files to ./ca, and the various certificates
under the ./certs directory.

Furthermore, instructions for configuring OpenVPN on Ubiquity EdgeOS
Routers and OpenVPN clients are included as well.

## Install the PreReqs

The pre-reqs are openssl, jq, j2cli, and cfssl.

* If on Linux, `make hostdeps`.
* Or if on OSX, you can probably install most of this with [https://brew.sh/](https://brew.sh/)

## How to use it

* Edit the Makefile to set the quantities of each cert to generate
* Create or link to an existing configuration
  * Create a new config under ./conf/config.yaml.<your_config>
  * Then create a link `ln -s ./config/config.yaml.<your_config> ./config.yaml`
  * Edit that configuration ./config.yaml
* Make everything `make`


## Ubiquiti EdgeOS OpenVPN Configuration

To configure the Router:

* customize the commands below
* ssh to the router
* paste the commands into the router

Please note that the current 1.9 version of Ubiquity EdgeOS, and thus
many of the ciphers are not current.

### Copy the certificates to the Router

Edit and run ./bin/ubiquiti.sh

### Configure OpenVPN on Ubiquiti

The nicely documented settings have been taken from
[GainfulShrimp](https://community.ubnt.com/t5/EdgeMAX/Secure-OpenVPN-server-setup-with-multi-factor-authentication/td-p/1240405) and ccustomized.

The following configs assume your Ubiquity has two networks
192.168.10.0/24 and 10.0.1.0/24.  You may have to modify code and
instructions to be specific to your setup.

```

# Start the configuration shell
configure

# The EdgeOS UI listens on port 443 TCP by default, which would clash with our
# OpenVPN server if it also tried to listen on port 443 using TCP, so we'll
# listen on port 1194 and use port-forwarding later so that we can reach our
# server from the outside
set interfaces openvpn vtun0 openvpn-option "--port 1194"

# By default, OpenVPN is peer-to-peer, but we want to put our instance in
# 'multi-user server' mode
set interfaces openvpn vtun0 mode server

# Enable TLS and assume server role during TLS handshake
set interfaces openvpn vtun0 openvpn-option --tls-server

# This line enables adaptive fast LZO compression. You must enable it on both
# server and client(s).
set interfaces openvpn vtun0 openvpn-option --comp-lzo

# The following line instructs OpenVPN to drop root privileges following
# initialisation - this is an important option for security
set interfaces openvpn vtun0 openvpn-option '--user nobody --group nogroup'

# We need to tell OpenVPN to remember the key after first reading it. Normally
# if you drop root privileges in OpenVPN, the daemon cannot be restarted (e.g.
# on SIGUSR1 signal), since it will now be unable to re-read protected key
# files.
# This option solves the problem by persisting keys across SIGUSR1 resets, so
# they don't need to be re-read.
set interfaces openvpn vtun0 openvpn-option --persist-key

# Keep the tunnel up across SIGUSR1 restarts. Also keep the same IP addresses.
set interfaces openvpn vtun0 openvpn-option --persist-tun
set interfaces openvpn vtun0 openvpn-option --persist-local-ip
set interfaces openvpn vtun0 openvpn-option --persist-remote-ip

# Check that the client is still reachable, every 8 seconds (unless a packet
# has been received from the client in the meantime). If no pings received from
# the client for 60 seconds, assume that the connection needs restarting.
set interfaces openvpn vtun0 openvpn-option '--keepalive 8 60'

# Set the verbosity level for the logs to a medium-low level. If you're having
# trouble getting things working, you will want to set this to a value between
# 6-11, where higher numbers give more debugging information
set interfaces openvpn vtun0 openvpn-option '--verb 3'

# We trust all of our clients, so will allow them to communicate with each
# other while connected via the VPN
set interfaces openvpn vtun0 openvpn-option --client-to-client

# Write a file with details of clients and the virtual IP address assigned to
# them, so that they hopefully always get the same address (this helps clients
# using persist-tun option)
set interfaces openvpn vtun0 openvpn-option '--ifconfig-pool-persist /config/auth/openvpn/vtun0-ipp.txt'

# The following lines instruct clients to direct all of their traffic (as much
# as possible) via the VPN. You should replace 192.168.2.1 with the address of
# your Edgerouter on your LAN (assuming that your Edgerouter is providing DNS
# for your LAN, that is).
# set interfaces openvpn vtun0 openvpn-option '--push redirect-gateway def1'
# set interfaces openvpn vtun0 openvpn-option '--push dhcp-option DNS 192.168.2.1'
#set interfaces openvpn vtun0 openvpn-option "--push dhcp-option DNS 8.8.8.8"
#set interfaces openvpn vtun0 openvpn-option "--push dhcp-option DNS 8.8.4.4"
set interfaces openvpn vtun0 openvpn-option "--push dhcp-option DNS 192.168.10.1"

# If you just want to make your LAN devices accessible from wherever you are
# but don't want to route internet traffic via your VPN tunnel, then leave out
# the following two lines and instead use something like (but replace the
# subnet and mask with your actual subnet and mask):
#set interfaces openvpn vtun0 openvpn-option "--push route 192.168.2.0 255.255.255.0"
set interfaces openvpn vtun0 openvpn-option "--push route 192.168.10.0 255.255.255.0"
set interfaces openvpn vtun0 openvpn-option "--push route 10.0.1.0 255.255.255.0"

# Enable HMAC authentication of the TLS control channel, using the key we
# generated earlier. The zero at the end is important, because it specifies the
# direction of the negotiation.
# With the following option enabled (and the corresponding option enabled on
# the clients), unauthorised clients are dropped before they can even attempt a
# TLS handshake.
set interfaces openvpn vtun0 openvpn-option '--tls-auth /config/auth/keys/ta.key 0'

# Enable our 'openvpn' PAM config for authentication of users using either TOTP
# or both password+TOTP (according to how you set up the PAM config earlier),
# on top of the standard PKI-based authentication:
# set interfaces openvpn vtun0 openvpn-option '--plugin /usr/lib/openvpn/openvpn-auth-pam.so openvpn'
# set interfaces openvpn vtun0 openvpn-option "--client-cert-not-required --username-as-common-name"

# Use 256bit AES-CBC cipher for main encryption. AES ciphers are considered
# strong and they are also well suited to ARM-powered clients such as iPhones.
# You can amend this to AES-128-CBC to trade off some security for slightly
# increased performance
set interfaces openvpn vtun0 openvpn-option '--cipher AES-256-CBC'

# All the advice online seems to recommend using the snappily-named cipher
# suite called TLS-DHE-RSA-WITH-AES-256-CBC-SHA for the control channel.
# However, if you use that name in the following line, you'll receive an error.
# That's because our OpenVPN server uses OpenSSL, which uses a different name
# for the same cipher suite:
set interfaces openvpn vtun0 openvpn-option '--tls-cipher DHE-RSA-AES256-SHA'

# The float option means that our clients can remain connected even if they
# move IP addresses after they first authenticate (so long as the packets still
# pass verification etc, of course). We want this because our clients might
# switch from wifi to cellular networks and back again, and we want to maximise
# the chances of our tunnel remaining usable during such events.
set interfaces openvpn vtun0 openvpn-option --float

# Use TCP protocol for the tunnel (for compatibility with restrictive firewalls
# remember), and passively accept connections from clients
set interfaces openvpn vtun0 openvpn-option "--proto tcp"
# set interfaces openvpn vtun0 protocol tcp-passive

# This is a virtual subnet used just for OpenVPN clients. I've chosen a
# relatively obscure subnet here, to minimise the chance of it clashing with
# whatever local subnet the client is connected to at the time.
set interfaces openvpn vtun0 server subnet 192.168.100.0/24

# Use the certificates (public keys) and private key that we generated earlier.
# If you chose to use 1024 bit strength when editing the 'vars' file, you'll
# need to specify "dh1024.pem" for the Diffie Hellman parameter file in the
# third line below:
set interfaces openvpn vtun0 tls ca-cert-file /config/auth/keys/ca.crt
set interfaces openvpn vtun0 tls cert-file /config/auth/keys/server.crt
set interfaces openvpn vtun0 tls key-file /config/auth/keys/server.key
set interfaces openvpn vtun0 tls dh-file /config/auth/keys/dh4096.pem

# Save the configuration
commit
save

```

### Configure Port Forwarding on Ubiquiti

```
#####################################################################
# Port Forwarding

configure

set port-forward wan-interface eth0
set port-forward lan-interface eth1

# Rule 6 is arbitrary
set port-forward rule 6 description 'OpenVPN TCP'
set port-forward rule 6 forward-to address 192.168.10.1
set port-forward rule 6 forward-to port 1194
set port-forward rule 6 original-port 1194
set port-forward rule 6 protocol tcp

#set port-forward rule 7 description 'OpenVPN UDP'
#set port-forward rule 7 forward-to address 192.168.10.1
#set port-forward rule 7 forward-to port 1194
#set port-forward rule 7 original-port 1194
#set port-forward rule 7 protocol udp

set service dns forwarding listen-on vtun0
# Udp would have been vtun1, but we are not setting that up
#set service dns forwarding listen-on vtun1

set firewall name WAN_LOCAL rule 5 action accept
set firewall name WAN_LOCAL rule 5 description 'Allow OpenVPN'
set firewall name WAN_LOCAL rule 5 destination port 1194
set firewall name WAN_LOCAL rule 5 log disable
#set firewall name WAN_LOCAL rule 5 protocol tcp_udp
set firewall name WAN_LOCAL rule 5 protocol tcp

commit
save

```

## Configuring Clients

### Installing on a Mac Client

* brew install Caskroom/cask/tunnelblick
* Copy a clientXX.ovpn file to the machine
* Double click on it
* Start the VPN connection from TunnelBlick

### Installing on an iOS Client

* Download the app "OpenVPN Connect"
* Connect your phone to your computer
* Open iTunes
* Select the phone view
* Find the OpenVPN Connect App
* Drag one of the clientXX.ovpn files onto the OpenVPN Connect File Area
* Go to iPhone Settings -> OpenVPN
* Enable "Force AES-CBC ciphersuites"
* Start the OpenVPN Connect app
* Click on the newly recognized profile to install it.
* From there on, you can start VPN from the OpenVPN connect app or from iOS settings

## Relevant Documentation

OpenVpn Documentation

* https://openvpn.net/index.php/open-source/documentation/howto.html

OpenVpn on Ubiquiti

* https://community.ubnt.com/t5/EdgeMAX/Secure-OpenVPN-server-setup-with-multi-factor-authentication/td-p/1240405

Key Usage / Purposes

* https://tools.ietf.org/html/rfc5280#section-4.2.1.3

Cfssl Docs

* https://github.com/cloudflare/cfssl/blob/master/doc/cmd/cfssl.txt#L72

OpenVpn Hardening Guide

* https://community.openvpn.net/openvpn/wiki/Hardening
