require "./hpai"
require "./dib"

class KNX
  # TODO:: support extended attributes available in KNXv2
  # This allows you to filter based on supported services
  class SearchRequest < BinData
    endian big

    custom header : Header = Header.new
    custom address : HPAI = HPAI.new

    def self.new(ip : Socket::IPAddress, protocol : ProtocolType = ProtocolType::IPv4UDP)
      parts = ip.address.split('.').map(&.to_u8)
      bytes = Bytes[parts[0], parts[1], parts[2], parts[3]]

      request = SearchRequest.new
      request.header.request_length = 14
      request.header.request_type = ::KNX::RequestTypes::SearchRequest
      request.address.ip_address = bytes
      request.address.port = ip.port.to_u16
      request
    end

    def self.perform_search(local_ip = "127.0.0.1", knx_multicast_addr = Socket::IPAddress.new("224.0.23.12", 3671))
      # Open a new UDP socket
      client = UDPSocket.new(Socket::Family::INET)
      client.bind("0.0.0.0", 0)

      # Join the multicast group
      client.join_group(knx_multicast_addr)

      # Build the request
      local_port = client.local_address.port
      request = KNX::SearchRequest.new(Socket::IPAddress.new(local_ip, local_port))

      # Send the request
      client.send(request, knx_multicast_addr)
      client.receive
    end
  end

  class SearchResponse < BinData
    endian big

    custom header : Header = Header.new
    custom address : HPAI = HPAI.new
    custom device : DeviceInfo = DeviceInfo.new
    custom services : SupportedServices = SupportedServices.new
  end
end
