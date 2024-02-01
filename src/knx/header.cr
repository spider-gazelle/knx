# frozen_string_literal: true, encoding: ASCII-8BIT

class KNX
  enum RequestTypes : UInt16
    SearchRequest              = 0x0201
    SearchResponse             = 0x0202
    DescriptionRequest         = 0x0203
    DescriptionResponse        = 0x0204
    ConnectRequest             = 0x0205
    ConnectResponse            = 0x0206
    ConnectionStateRequest     = 0x0207
    ConnectionStateResponse    = 0x0208
    DisconnectRequest          = 0x0209
    DisconnectResponse         = 0x020A
    DeviceConfigurationRequest = 0x0310
    DeviceConfigurationACK     = 0x0311
    TunnellingRequest          = 0x0420
    TunnellingACK              = 0x0421
    RoutingIndication          = 0x0530
    RoutingLostMessage         = 0x0531
    RoutingBusy                = 0x0532

    RemoteDiagnosticRequest  = 0x0740
    RemoteDiagnosticResponse = 0x0741
    RemoteBasicConfigRequest = 0x0742
    RemoteResetRequest       = 0x0743

    # Object Server
    ObjectServer = 0xF080

    # This wraps a regular KNX frame
    SecureWrapper = 0x0950

    # KNXnet/IP services (tunneling)
    SecureSessionRequest      = 0x0951
    SecureSessionResponse     = 0x0952
    SecureSessionAuthenticate = 0x0953
    SecureSessionStatus       = 0x0954
    SecureTimerNotify         = 0x0955
  end

  # http://www.openremote.org/display/forums/KNX+IP+Connection+Headers
  class Header < BinData
    endian big

    field header_length : UInt8 = 0x06 # Length 6 (always for version 1)
    field version : UInt8 = 0x10_u8    # version 1
    field request_type : RequestTypes = RequestTypes::RoutingIndication
    field request_length : UInt16

    # See: https://youtu.be/UjOBudAG654?t=42m20s
    group :wrapper, onlyif: ->{ request_type == RequestTypes::SecureWrapper } do
      field session_id : UInt16 # Not sure what this should be

      bit_field do
        bits 48, :timestamp         # Timestamp for multicast messages, sequence number for tunneling
        bits 48, :knx_serial_number # Serial of the device - random constant
      end

      # Random number
      field message_tag : UInt16

      # header + security info + cbc_mac == 38
      #   6          16            16    == 38
      field encrypted_frame : String, length: ->{ parent.request_length - 38 }
      # Encryption: Timestamp + Serial Number + Tag + 0x01 + counter (1 byte), starting at 0
      # Single key for each multicast group: PID_BACKBONE_KEY
      # https://en.wikipedia.org/wiki/CCM_mode

      # https://en.wikipedia.org/wiki/CBC-MAC (always 128bit (16bytes) in KNX)
      # Timestamp + Serial Number + Tag + frame length (2 bytes)
      field cmac : String, length: ->{ 16 }
    end

    group :timer, onlyif: ->{ request_type == RequestTypes::SecureTimerNotify } do
      bit_field do
        bits 48, :timestamp         # Current time as understood by the device
        bits 48, :knx_serial_number # Serial of the device
      end
      field message_tag : UInt16 # Random number

      # Timestamp + Serial Number + Tag + frame length (2 bytes) == 0x0000
      field cmac : String, length: ->{ 16 }
    end
  end
end
