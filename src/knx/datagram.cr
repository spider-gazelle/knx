require "./cemi"

class KNX
  class DatagramBuilder
    property header : Header
    property cemi : CEMI

    delegate :data, to: @cemi

    delegate :action_type, to: @cemi
    delegate :action_type=, to: @cemi

    delegate :source_address, to: @cemi
    delegate :source_address=, to: @cemi

    delegate :destination_address, to: @cemi
    delegate :destination_address=, to: @cemi

    def to_slice
      io = IO::Memory.new
      io.write_bytes @header
      io.write @cemi.to_slice

      # inject the request length
      @header.request_length = length = io.size.to_u16
      io.pos = 4
      io.write_bytes length, IO::ByteFormat::BigEndian

      io.to_slice
    end

    protected def present?(data)
      !(data.nil? || data.empty?)
    end

    protected def initialize(
      address : String,
      msg_code : MsgCode,
      no_repeat : Bool = false,
      broadcast : Bool = false,
      priority : Priority = Priority::LOW,
      hop_count : UInt8 = 7,
      request_type : RequestTypes = RequestTypes::RoutingIndication,
      source : String = "0.0.0",
    )
      @cemi = CEMI.new
      @cemi.destination_address = Address.parse(address)
      @cemi.source_address = IndividualAddress.parse_friendly(source)

      @cemi.msg_code = msg_code
      @cemi.is_standard_frame = true
      @cemi.no_repeat = no_repeat
      @cemi.broadcast = broadcast
      @cemi.priority = priority

      @cemi.is_group_address = destination_address.group?
      @cemi.hop_count = hop_count

      @header = Header.new
      @header.version = 0x10_u8
      @header.request_type = request_type
    end
  end

  class ActionDatagram < DatagramBuilder
    def initialize(address : String, data_array : Bytes, **options)
      super(address, **options)

      # Set the protocol control information
      @cemi.action_type = destination_address.group? ? ActionType::GroupWrite : ActionType::IndividualWrite
      @cemi.data = data_array
      @cemi.tpci = TpciType::UnnumberedData
    end
  end

  class StatusDatagram < DatagramBuilder
    def initialize(address, **options)
      super(address, **options)

      # Set the protocol control information
      @action_type = destination_address.group? ? ActionType::GroupRead : ActionType::IndividualRead
      @cemi.data = Bytes.new(0)
      @cemi.tpci = TpciType::UnnumberedData
    end
  end

  class ResponseDatagram < DatagramBuilder
    def initialize(io : IO, two_level_group = false)
      @header = io.read_bytes Header
      @cemi = io.read_bytes CEMI
      @cemi.two_level_group = two_level_group
    end
  end
end
