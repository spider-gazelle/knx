require "log"
require "bindata"
require "./knx/header"
require "./knx/cemi"
require "./knx/address"
require "./knx/datagram"
require "./knx/datapoint"
require "./knx/discovery/search_request"
require "./knx/connection/connect_request"
require "./knx/connection/connect_state_request"
require "./knx/connection/disconnect_request"
require "./knx/connection/tunnel_request"

# Discovery and negotiation: http://knxer.net/?p=78

class KNX
  Log = ::App::Log.for("knx")

  property priority : Priority
  property? no_repeat : Bool
  property? broadcast : Bool
  property hop_count : UInt8
  property cmac_key : Bytes?
  property source : String

  def initialize(
    @priority = Priority::LOW,
    @no_repeat = true,
    @broadcast = true,
    @hop_count = 6_u8,
    @two_level_group = false,
    @cmac_key = nil,
    @source = "0.0.0"
  )
  end

  def action(
    address : String,
    data,
    msg_code : MsgCode = MsgCode::DataIndicator,
    no_repeat : Bool = @no_repeat,
    broadcast : Bool = @broadcast,
    priority : Priority = @priority,
    hop_count : UInt8 = @hop_count,
    request_type : RequestTypes = RequestTypes::RoutingIndication,
    source : String = @source
  ) : ActionDatagram
    raw = case data
          when Bool
            data ? Bytes[1] : Bytes[0]
          when Int
            io = IO::Memory.new
            io.write_bytes(data, IO::ByteFormat::BigEndian)

            bytes = io.to_slice
            index = 0
            bytes.each_with_index do |byte, i|
              next if byte == 0
              index = i
              break
            end
            bytes[index..-1]
          when Float, String, Time
            KNX.datapoint(data).to_bytes
          when Datapoint
            data.to_bytes
          else
            # Must support `to_slice`
            data.to_slice
          end

    ActionDatagram.new(
      address, raw,
      msg_code: msg_code,
      no_repeat: no_repeat,
      broadcast: broadcast,
      priority: priority,
      hop_count: hop_count,
      request_type: request_type,
      source: source
    )
  end

  def status(
    address : String,
    msg_code : MsgCode = MsgCode::DataRequest,
    no_repeat : Bool = @no_repeat,
    broadcast : Bool = @broadcast,
    priority : Priority = @priority,
    hop_count : UInt8 = @hop_count,
    request_type : RequestTypes = RequestTypes::RoutingIndication,
    source : String = @source
  )
    StatusDatagram.new(
      address,
      msg_code: msg_code,
      no_repeat: no_repeat,
      broadcast: broadcast,
      priority: priority,
      hop_count: hop_count,
      request_type: request_type,
      source: source
    )
  end

  def read(data : Bytes, two_level_group = @two_level_group)
    io = IO::Memory.new(data)

    # Check for an encrpyted packet
    if data[2] == 0x09
      header = io.read_bytes(Header)
      if header.request_type == RequestTypes::SecureWrapper
        raise "KNX security not currently implemented"
      else
        io.rewind
        ResponseDatagram.new(io, two_level_group)
      end
    else
      ResponseDatagram.new(io, two_level_group)
    end
  end
end
