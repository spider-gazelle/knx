class KNX
  enum ConnectType
    # Data connection used to configure a KNXnet/IP device
    DeviceManagement = 0x03

    # Data connection used to forward KNX telegrams between
    # two KNXnet/IP devices.
    Tunnel = 0x04

    # Data connection used for configuration and data transfer
    # with a remote logging server.
    RemoteLogging = 0x06

    # Data connection used for data transfer with a remote
    # configuration server.
    RemoteConfiguration = 0x07

    # Data connection used for configuration and data transfer
    # with an Object Server in a KNXnet/IP device.
    ObjectServer = 0x08
  end

  # Connect Request Information
  class CRI < BinData
    endian :big

    LENGTH = 4

    uint8 length, value: ->{ 4 }
    enum_field UInt8, connect_type : ConnectType = ConnectType::Tunnel
    bit_field do
      bool bus_monitor_tunnel
      bits 4, :_reserved_
      bool raw_tunnel
      bool data_link_tunnel
      bits 1, :_reserved2_
    end
    uint8 reserved
  end
end
