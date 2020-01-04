class KNX
  class FourByteFloat < Datapoint
    property value : Float32 = 0.0_f32

    def initialize(@value : Bool)
    end

    def initialize(data : Bytes)
      from_datapoint data
    end

    def from_datapoint(data : Bytes)
      io = IO::Memory.new(data)
      @value = io.read_bytes(Float32, IO::ByteFormat::BigEndian)
    end

    def to_datapoint : Bytes
      io = IO::Memory.new(4)
      io.write_bytes(@value, IO::ByteFormat::BigEndian)
      io.to_slice
    end
  end
end
