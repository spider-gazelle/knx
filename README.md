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

and support for Tunnelling

```crystal
require "knx/tunnel_client"

# connect to the interface
interface_ip = Socket::IPAddress.new("192.168.0.10", 3671)
udp_socket = UDPSocket.new
udp_socket.connect interface_ip.address, interface_ip.port

# determine our local IP address
local_ip = udp_socket.local_address

# configure the client
client = KNX::TunnelClient.new(control_ip)

is_connected = false
client.on_state_change do |connected, error|
  # we should maintain the connection
  if connected
    spawn do
      loop do
        break unless is_connected
        sleep 60.seconds
        # sends a connection state request
        client.query_state
      end
    end
  end
end

# send the data down the transport
client.on_transmit { |bytes| udp_socket.write bytes }

# we received a tunnelled request from the interface (forwarded broadcast packets)
client.on_message do |cemi|
  cemi.destination_address # => 1/2/55
  cemi.data # => Bytes (can process data based on the address)
end

# process any incoming data on the socket
spawn do
  message = Bytes.new(512)
  loop do
    bytes_read, client_addr = udp_socket.receive(message)
    client.process(message[0, bytes_read])
  end
end

# send any messages
client.status("1/2/55")

client.action("1/2/55", true)
client.action("2/2/55", 3)
client.action("1/3/55", 8.4)
```

## License

MIT
