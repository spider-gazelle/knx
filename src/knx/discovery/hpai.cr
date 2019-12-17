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
    bytes ip_address, length: ->{ 4 }
    uint16 port
  end
end
