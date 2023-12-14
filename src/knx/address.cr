class KNX
  # ------------------------
  #    Address Processing
  # ------------------------
  #           +-----------------------------------------------+
  # 16 bits   |              INDIVIDUAL ADDRESS               |
  #           +-----------------------+-----------------------+
  #           | OCTET 0 (high byte)   |  OCTET 1 (low byte)   |
  #           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    bits   | 7| 6| 5| 4| 3| 2| 1| 0| 7| 6| 5| 4| 3| 2| 1| 0|
  #           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #           |  Subnetwork Address   |                       |
  #           +-----------+-----------+     Device Address    |
  #           |(Area Adrs)|(Line Adrs)|                       |
  #           +-----------------------+-----------------------+

  #           +-----------------------------------------------+
  # 16 bits   |             GROUP ADDRESS (3 level)           |
  #           +-----------------------+-----------------------+
  #           | OCTET 0 (high byte)   |  OCTET 1 (low byte)   |
  #           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    bits   | 7| 6| 5| 4| 3| 2| 1| 0| 7| 6| 5| 4| 3| 2| 1| 0|
  #           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #           |  | Main Grp  | Midd G |       Sub Group       |
  #           +--+--------------------+-----------------------+

  #           +-----------------------------------------------+
  # 16 bits   |             GROUP ADDRESS (2 level)           |
  #           +-----------------------+-----------------------+
  #           | OCTET 0 (high byte)   |  OCTET 1 (low byte)   |
  #           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #    bits   | 7| 6| 5| 4| 3| 2| 1| 0| 7| 6| 5| 4| 3| 2| 1| 0|
  #           +--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+--+
  #           |  | Main Grp  |            Sub Group           |
  #           +--+--------------------+-----------------------+
  abstract class Address < BinData
    endian :big

    def self.parse(input)
      case input
      when Int
        io = IO::Memory.new(2)
        io.write_bytes input.to_u16, IO::ByteFormat::BigEndian
        io.rewind
        io.read_bytes(self, IO::ByteFormat::BigEndian)
      when String
        addr = parse_friendly(input)
        raise "address parsing failed" unless addr
        addr
      else
        io = IO::Memory.new(input.to_slice)
        io.read_bytes(self)
      end
    end

    def to_i
      # 16-bit unsigned, network (big-endian)
      io = IO::Memory.new(2)
      io.write_bytes self, IO::ByteFormat::BigEndian
      io.rewind
      io.read_bytes(UInt16, IO::ByteFormat::BigEndian)
    end

    def group?
      true
    end

    abstract def to_s : String
  end

  class GroupAddress < Address
    endian :big

    bit_field do
      bits 1, :_reserved_, default: 0_u8
      bits 4, :main_group
      bits 3, :middle_group
    end
    uint8 :sub_group

    def to_s : String
      "#{main_group}/#{middle_group}/#{sub_group}"
    end

    def self.parse_friendly(string)
      result = string.split('/')
      if result.size == 3
        address = GroupAddress.new
        address.main_group = result[0].to_u8
        address.middle_group = result[1].to_u8
        address.sub_group = result[2].to_u8
        address
      else
        raise "invalid group address: #{string}"
      end
    end
  end

  class GroupAddress2Level < Address
    endian :big

    bit_field do
      bits 1, :_reserved_, default: 0_u8
      bits 4, :main_group
      bits 11, :sub_group
    end

    def to_s : String
      "#{main_group}/#{sub_group}"
    end

    def self.parse_friendly(string)
      result = string.split('/')
      if result.size == 2
        address = GroupAddress2Level.new
        address.main_group = result[0].to_u8
        address.sub_group = result[1].to_u16
        address
      else
        raise "invalid 2 level group address: #{string}"
      end
    end
  end

  class IndividualAddress < Address
    endian :big

    bit_field do
      bits 4, :area_address
      bits 4, :line_address
    end
    uint8 :device_address

    def to_s : String
      "#{area_address}.#{line_address}.#{device_address}"
    end

    def group?
      false
    end

    def self.parse_friendly(string)
      result = string.split('.')
      if result.size == 3
        address = IndividualAddress.new
        address.area_address = result[0].to_u8
        address.line_address = result[1].to_u8
        address.device_address = result[2].to_u8
        address
      else
        raise "invalid individual address: #{string}"
      end
    end
  end
end
