require "socket"
require "./connect_state_request"

class KNX
  # The server can send a Disconnect request and that the client will respond
  # with a Disconnect response.
  class DisconnectRequest < ConnectStateRequest
    def self.new(
      channel_id : Int,
      control : Socket::IPAddress,
      protocol : ProtocolType = ProtocolType::IPv4UDP
    )
      request = super(channel_id, control, protocol)
      request.header.request_type = ::KNX::RequestTypes::DisconnectRequest
      request
    end
  end

  class DisconnectResponse < ConnectStateResponse
    def self.new(channel_id : Int)
      response = super(channel_id)
      response.header.request_type = ::KNX::RequestTypes::DisconnectResponse
      response
    end
  end
end
