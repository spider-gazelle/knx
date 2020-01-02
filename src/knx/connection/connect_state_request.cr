require "socket"
require "./error_status"

class KNX
  # Connection state request / response can be considered as a heartbeat mechanism.
  # It enables KNXnet/IP client to ping the server in regular intervals (every 60 seconds)
  # After a while (120 seconds) server will conclude that the client is not available
  # and it will terminate the tunnelling connection if the client fails to send
  # the Connection State request.
  class ConnectStateRequest < BinData
    endian big

    custom header : Header = Header.new
    uint8 channel_id
    enum_field UInt8, status : ConnectionError = ConnectionError::NoError
    custom control_endpoint : HPAI = HPAI.new

    def self.new(
      channel_id : Int,
      control : Socket::IPAddress,
      protocol : ProtocolType = ProtocolType::IPv4UDP
    )
      request = self.new
      request.channel_id = channel_id.to_u8
      request.header.request_length = (HPAI::LENGTH + 2 + request.header.header_length).to_u16
      request.header.request_type = ::KNX::RequestTypes::ConnectionStateRequest
      request.control_endpoint.ip_address = control
      request.control_endpoint.protocol = protocol
      request
    end
  end

  class ConnectStateResponse < BinData
    endian big

    custom header : Header = Header.new
    uint8 channel_id
    enum_field UInt8, status : ConnectionError = ConnectionError::NoError
  end
end
