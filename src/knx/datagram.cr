require "./cemi"

class KNX
  class DatagramBuilder
    property header : Header
    property cemi : CEMI
    property source_address : Address
    property destination_address : Address
    property data : IO::Memory = IO::Memory.new(0)
    property action_type : ActionType = ActionType::GroupRead

    def to_slice
      raw_data = @data.to_slice
      write_data = if @cemi.apply_apci(@action_type, raw_data)
                     @cemi.data_length = raw_data.size.to_u8

                     if raw_data.size > 1
                       raw_data[1..-1]
                     else
                       Bytes.new(0)
                     end
                   elsif raw_data.size > 0
                     @cemi.data_length = raw_data.size.to_u8
                     raw_data
                   else
                     @cemi.data_length = 0_u8
                     Bytes.new(0)
                   end

      @cemi.source_address = @source_address.to_slice
      @cemi.destination_address = @destination_address.to_slice

      # 17 == header + cemi
      @header.request_length = (write_data.size + 17).to_u16

      io = IO::Memory.new
      io.write_bytes @header
      io.write_bytes @cemi
      io.write write_data
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
      request_type : RequestTypes = RequestTypes::RoutingIndication
    )
      address = parse(address)

      @cemi = CEMI.new
      @cemi.msg_code = msg_code
      @cemi.is_standard_frame = true
      @cemi.no_repeat = no_repeat
      @cemi.broadcast = broadcast
      @cemi.priority = priority

      @cemi.is_group_address = address.group?
      @cemi.hop_count = hop_count

      @header = Header.new
      @header.version = 0x10_u8
      @header.request_type = request_type

      @source_address = IndividualAddress.parse_friendly("0.0.1")
      @destination_address = address

      @cemi.source_address = @source_address.to_slice
      @cemi.destination_address = @destination_address.to_slice
    end

    protected def parse(address) : Address
      count = address.count('/')
      case count
      when 2
        GroupAddress.parse_friendly(address)
      when 1
        GroupAddress2Level.parse_friendly(address)
      else
        IndividualAddress.parse_friendly(address)
      end
    end
  end

  class ActionDatagram < DatagramBuilder
    def initialize(address : String, data_array : Bytes, **options)
      super(address, **options)

      # Set the protocol control information
      @action_type = @destination_address.group? ? ActionType::GroupWrite : ActionType::IndividualWrite
      @cemi.apply_apci(@action_type, data_array)
      @cemi.tpci = TpciType::UnnumberedData

      if data_array.size > 0
        @cemi.data_length = data_array.size.to_u8
        @data = IO::Memory.new(data_array)
      end
    end
  end

  class StatusDatagram < DatagramBuilder
    def initialize(address, **options)
      super(address, **options)

      # Set the protocol control information
      @action_type = @destination_address.group? ? ActionType::GroupRead : ActionType::IndividualRead
      @cemi.apply_apci(@action_type)
      @cemi.tpci = TpciType::UnnumberedData
    end
  end

  class ResponseDatagram < DatagramBuilder
    def initialize(io : IO, two_level_group = false)
      @header = io.read_bytes Header
      @cemi = io.read_bytes CEMI

      # Header == 6 bytes
      # cemi min is == 11 bytes
      data_length = @header.request_length - 17 - @cemi.info_length
      if @cemi.data_length > data_length
        @data.write_byte @cemi.data
        @action_type = ActionType.from_value(@cemi.apci)
      else
        acpi = @cemi.data | (@cemi.apci << 6)
        @action_type = ActionType.from_value?(acpi) || ActionType.from_value(@cemi.apci)
      end

      bytes = Bytes.new(data_length)
      io.read_fully bytes
      @data.write bytes
      @data.rewind

      @source_address = IndividualAddress.parse(@cemi.source_address)

      if !@cemi.is_group_address
        @destination_address = IndividualAddress.parse(@cemi.destination_address)
      elsif two_level_group
        @destination_address = GroupAddress2Level.parse(@cemi.destination_address)
      else
        @destination_address = GroupAddress.parse(@cemi.destination_address)
      end
    end
  end
end
