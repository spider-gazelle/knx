class KNX
  class DpString < Datapoint
    property value : String = ""

    def initialize(@value : String)
    end

    def initialize(data : Bytes)
      from_bytes data
    end

    def from_bytes(data : Bytes)
      io = IO::Memory.new(data.size)
      data.each do |byte|
        break if byte == 0_u8
        io.write_byte byte
      end
      @value = String.new(io.to_slice)
    end

    def to_bytes : Bytes
      io = IO::Memory.new(@value.size + 1)
      io.write @value.to_slice
      io.write_byte(0_u8)
      bytes = io.to_slice
      return bytes[0..13] if bytes.size > 14
      bytes
    end
  end
end
