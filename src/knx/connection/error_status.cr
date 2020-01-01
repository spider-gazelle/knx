class KNX
  enum ConnectionError
    # The connection state is normal.
    NoError = 0

    # requested host protocol is not supported
    HostProtocolIssue

    # requested protocol version is not supported
    VersionNotSupported

    # received sequence number is out of order.
    SequenceNumber

    # cannot find an active data connection with the specified ID.
    ConnectionID = 0x21

    # The requested connection type is not supported
    ConnectionType

    # One or more requested connection options are not supported
    ConnectionOption

    # maximum amount of concurrent connections is already occupied.
    NoMoreConnections

    # Individual Address is used multiple times
    NoMoreUniqueConnections

    # error concerning the data connection with the specified ID.
    DataConnection

    # error concerning the KNX subnetwork connection with the specified ID.
    SubnetworkIssue

    # requested tunnelling layer is not supported
    TunnellingLayer = 0x29
  end

  class ErrorStatus < BinData
    LENGTH = 2

    uint8 length, value: ->{ 1 }
    enum_field UInt8, status : ConnectionError = ConnectionError::NoError
  end
end
