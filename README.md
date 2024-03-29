# Crystal KNX

Constructs [KNX standard](https://en.wikipedia.org/wiki/KNX_(standard)) datagrams that make it easy to communicate with devices on KNX networks.

[![CI](https://github.com/spider-gazelle/knx/actions/workflows/ci.yml/badge.svg)](https://github.com/spider-gazelle/knx/actions/workflows/ci.yml)


## Usage

```crystal
require "knx"

knx = KNX.new
datagram = knx.read(bytes)
datagram.source_address.to_s
# => "2.3.4"

datagram.destination_address.to_s
# => "3/4/5"

datagram.data # Returns a byte array
# => [1]

# ...

request = knx.action("1/2/0", true)
bytes = request.to_slice

request = knx.action("1/2/3", 150)
bytes = request.to_slice

# Send byte_string to KNX network to execute the request
# Supports multicast, unicast and TCP/IP tunnelling

```

There is also support for [KNX BAOS devices](http://www.weinzierl.de/index.php/en/all-knx/knx-devices-en) devices:


```crystal
require "knx/object_server"

os = KNX::ObjectServer.new
datagram = os.read(bytes)

# Can return multiple values
datagram.data.size #=> 1

# Get the item index we are reading
datagram.data[0].id
# => 12

datagram.data[0].value # Returns bytes
# => Bytes[1]

# ...

request = os.action(1, true)
bytes = request.to_slice

# Send byte_string to KNX BAOS server to execute the request
# This protocol was designed to be sent over TCP/IP

```


## License

MIT
