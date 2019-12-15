# frozen_string_literal: true, encoding: ASCII-8BIT

class KNX
  enum RequestTypes
    SearchRequest              = 0x0201
    SearchResponse             = 0x0202
    DescriptionRequest         = 0x0203
    DescriptionResponse        = 0x0204
    ConnectRequest             = 0x0205
    ConnectResponse            = 0x0206
    ConnectionstateRequest     = 0x0207
    ConnectionstateResponse    = 0x0208
    DisconnectRequest          = 0x0209
    DisconnectResponse         = 0x020A
    DeviceConfigurationRequest = 0x0310
    DeviceConfigurationACK     = 0x0311
    TunnellingRequest          = 0x0420
    TunnellingACK              = 0x0421
    RoutingIndication          = 0x0530
    RoutingLostMessage         = 0x0531

    RoutingBusy              = 0x0532
    RemoteDiagnosticRequest  = 0x0740
    RemoteDiagnosticResponse = 0x0741
    RemoteBasicConfigRequest = 0x0742
    RemoteResetRequest       = 0x0743

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

    uint8 :header_length, default: 0x06 # Length 6 (always for version 1)
    uint8 :version
    enum_field UInt16, request_type : RequestTypes = RequestTypes::RoutingIndication
    uint16 :request_length

    # See: https://youtu.be/UjOBudAG654?t=42m20s
    group :wrapper, onlyif: ->{ request_type == RequestTypes::SecureWrapper } do
      uint16 :session_id # Not sure what this should be

      bit_field do
        bits 48, :timestamp         # Timestamp for multicast messages, sequence number for tunneling
        bits 48, :knx_serial_number # Serial of the device - random constant
      end
      uint16 :message_tag # Random number

      # header + security info + cbc_mac == 38
      #   6          16            16    == 38
      string :encrypted_frame, length: ->{ parent.request_length - 38 }
      # Encryption: Timestamp + Serial Number + Tag + 0x01 + counter (1 byte), starting at 0
      # Single key for each multicast group: PID_BACKBONE_KEY
      # https://en.wikipedia.org/wiki/CCM_mode

      # https://en.wikipedia.org/wiki/CBC-MAC (always 128bit (16bytes) in KNX)
      # Timestamp + Serial Number + Tag + frame length (2 bytes)
      string :cmac, length: ->{ 16 }
    end

    group :timer, onlyif: ->{ request_type == RequestTypes::SecureTimerNotify } do
      bit_field do
        bits 48, :timestamp         # Current time as understood by the device
        bits 48, :knx_serial_number # Serial of the device
      end
      uint16 :message_tag # Random number

      # Timestamp + Serial Number + Tag + frame length (2 bytes) == 0x0000
      string :cmac, length: ->{ 16 }
    end
  end
end
