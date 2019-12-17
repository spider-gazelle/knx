class KNX
  enum ProtocolType
    IPv4UDP = 1
    IPv4TCP = 2
  end

  # Host Protocol Address Information
  class HPAI < BinData
    endian :big

    uint8 length, default: 8_u8
    enum_field UInt8, protocol : ProtocolType = ProtocolType::IPv4UDP
    bytes ip_addr, length: ->{ 4 }
    uint16 port

    def self.new(ip : Socket::IPAddress)
      hpai = HPAI.new
      hpai.ip_address = ip
      hpai
    end

    def ip_address
      str = "#{ip_addr[0]}.#{ip_addr[1]}.#{ip_addr[2]}.#{ip_addr[3]}"
      Socket::IPAddress.new(str, port.to_i)
    end

    def ip_address=(address : String)
      parts = address.split('.').map(&.to_u8)
      @ip_addr = Bytes[parts[0], parts[1], parts[2], parts[3]]
      address
    end

    def ip_address=(ip : Socket::IPAddress)
      self.ip_address = ip.address
      @port = ip.port.to_u16
      ip
    end
  end
end
