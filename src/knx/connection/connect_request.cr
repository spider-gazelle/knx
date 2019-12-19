require "socket"
require "./cri"
require "./crd"

class KNX
  class ConnectRequest < BinData
    endian big

    custom header : Header = Header.new
    custom control_endpoint : HPAI = HPAI.new
    custom data_endpoint : HPAI = HPAI.new
    custom cri : CRI = CRI.new

    def self.new(
      control : Socket::IPAddress,
      data : Socket::IPAddress? = nil,
      protocol : ProtocolType = ProtocolType::IPv4UDP
    )
      request = ConnectRequest.new
      request.header.request_length = ((HPAI::LENGTH * 2) + CRI::LENGTH + request.header.header_length).to_u16
      request.header.request_type = ::KNX::RequestTypes::ConnectRequest

      request.control_endpoint.ip_address = control
      request.control_endpoint.protocol = protocol

      request.data_endpoint.ip_address = data || control
      request.data_endpoint.protocol = protocol

      request.cri.data_link_tunnel = true

      request
    end
  end

  class ConnectResponse < BinData
    endian big

    custom header : Header = Header.new
    custom error : ErrorStatus = ErrorStatus.new
    custom control_endpoint : HPAI = HPAI.new
    custom crd : CRD = CRD.new
  end
end
