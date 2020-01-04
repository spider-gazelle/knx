class KNX
  class IndicationRequest < BinData
    endian big

    custom header : Header = Header.new
    custom cemi : CEMI = CEMI.new
    bytes extended_bytes, length: ->{ header.request_length - 17 - cemi.info_length }

    def payload : Bytes
      data_length = @header.request_length - 17 - @cemi.info_length
      if @cemi.data_length > data_length
        io = IO::Memory.new(@cemi.data_length)
        io.write_byte @cemi.data
        io.write @extended_bytes
        io.to_slice
      else
        @extended_bytes
      end
    end

    def apply_apci(action : ActionType | Int, data = nil)
      raw_data = data ? data.to_slice : Bytes.new(0)
      used_first_byte = @cemi.apply_apci(action, raw_data)

      if used_first_byte
        @extended_bytes = if raw_data.size > 1
                            raw_data[1..-1]
                          else
                            Bytes.new(0)
                          end
      else
        @extended_bytes = raw_data
      end

      @cemi.data_length = raw_data.size.to_u8

      nil
    end

    def self.new(
      address : String,
      action : ActionType,
      msg_code : MsgCode = MsgCode::DataIndicator,
      no_repeat : Bool = false,
      broadcast : Bool = false,
      priority : Priority = Priority::LOW,
      hop_count : UInt8 = 7,
      data = Bytes.new(0)
    )
      request = IndicationRequest.new
      request.header.request_type = RequestTypes::RoutingIndication

      request.cemi.msg_code = msg_code
      request.cemi.is_standard_frame = true
      request.cemi.no_repeat = no_repeat
      request.cemi.broadcast = broadcast
      request.cemi.priority = priority
      request.cemi.is_group_address = address.is_group?
      request.cemi.hop_count = hop_count

      source_address = IndividualAddress.parse_friendly("0.0.1")
      destination_address = Address.parse(address)
      request.cemi.source_address = @source_address.to_slice
      request.cemi.destination_address = @destination_address.to_slice

      request.apply_apci(action, data)

      # Header == 6 bytes
      # cemi min is == 11 bytes
      request.header.request_length = 17 + request.cemi.info_length + request.extended_bytes.size

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
end
