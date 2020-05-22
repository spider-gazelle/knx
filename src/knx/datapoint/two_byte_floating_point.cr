class KNX
  class TwoByteFloatingPoint < Datapoint
    property value : Float64 = 0.0

    def initialize(data : Int | Float)
      @value = data.to_f64
    end

    def initialize(data : Bytes)
      from_bytes data
    end

    def from_bytes(data : Bytes)
      m = (data[0].bits(0..2).to_i << 8) | data[1]
      signed = data[0].bit(7) == 1

      val = if signed
              m = m - 1
              m = ~m & 0x07FF
              m * -1
            else
              m
            end

      power = (data[0].bits(3..6)).to_i
      calc = 0.01 * val

      @value = (calc * (2 ** power)).to_f64.round(2)
    end

    def to_bytes : Bytes
      raise "input value is not in a valid range" if value <= -670761.0 || value >= 670761.0

      v = (@value * 100.0).round
      e = 0

      loop do
        break unless v < -2048.0
        v = v / 2
        e += 1
      end

      loop do
        break unless v > 2047.0
        v = v / 2
        e += 1
      end

      mantissa = 0
      signed = if v < 0
                 mantissa = -(v.to_i)
                 mantissa = ~mantissa & 0x07FF
                 mantissa = mantissa + 1
                 true
               else
                 mantissa = v.to_i
                 false
               end

      datapoint = Bytes[0, 0]
      datapoint[0] = 0x80 if signed
      datapoint[0] = datapoint[0] | (e.bits(0..3) << 3)
      datapoint[0] = datapoint[0] | (mantissa >> 8).bits(0..2)
      datapoint[1] = (mantissa & 0xFF).to_u8
      datapoint
    end
  end
end
