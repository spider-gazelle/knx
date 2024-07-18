require "socket"
require "./cri"
require "./crd"
require "./error_status"

class KNX
  class TunnelRequest < BinData
    endian big

    field header : Header = Header.new
    field length : UInt8, value: ->{ 4 }
    field channel_id : UInt8
    field sequence : UInt8
    field status : ConnectionError = ConnectionError::NoError

    field cemi : CEMI = CEMI.new

    def self.new(
      channel_id : Int,
      cemi : CEMI,
      sequence : Int = 0
    )
      request = TunnelRequest.new
      request.header.request_type = RequestTypes::TunnellingRequest
      request.header.request_length = (cemi.to_slice.size + 4 + request.header.header_length).to_u16

      request.channel_id = channel_id.to_u8
      request.sequence = sequence.to_u8

      request.cemi = cemi

      request
    end

    def source_address : String
      KNX::IndividualAddress.parse(@cemi.source_address).to_s
    end

    def destination_address : String
      if @cemi.is_group_address
        KNX::GroupAddress.parse(@cemi.destination_address).to_s
      else
        KNX::IndividualAddress.parse(@cemi.destination_address).to_s
      end
    end
  end

  class TunnelResponse < BinData
    endian big

    field header : Header = Header.new
    field length : UInt8, value: ->{ 4 }
    field channel_id : UInt8
    field sequence : UInt8
    field status : ConnectionError = ConnectionError::NoError

    def self.new(
      channel_id : Int,
      sequence : Int
    )
      response = TunnelResponse.new
      response.header.request_type = RequestTypes::TunnellingACK
      response.header.request_length = (4 + response.header.header_length).to_u16

      response.channel_id = channel_id.to_u8
      response.sequence = sequence.to_u8

      response
    end
  end
end
