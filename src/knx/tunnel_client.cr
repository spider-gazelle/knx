require "bindata"
require "../knx"

class KNX
  class TunnelClient
    def initialize(
      @control : Socket::IPAddress,
      @timeout : Time::Span = 3.seconds,
      @max_retries : Int32 = 5
    )
    end

    getter control : Socket::IPAddress
    getter? connected : Bool = false
    getter channel_id : UInt8 = 0_u8
    getter sequence : UInt8 = 0_u8
    property timeout : Time::Span
    property max_retries : Int32

    alias Request = ConnectRequest | ConnectStateRequest | DisconnectRequest | TunnelRequest

    @request_queue : Array(Request) = [] of Request
    @channel : Channel(Nil) = Channel(Nil).new
    @waiting : Bool = false
    @retries : Int32 = 0
    @mutex : Mutex = Mutex.new

    protected def send(request : Request)
      send_now = @mutex.synchronize do
        @request_queue << request
        if request.is_a?(KNX::TunnelRequest)
          request.sequence = next_sequence_no
        end
        @request_queue.size == 1
      end

      perform_send(request) if send_now
    end

    protected def perform_send(request : Request)
      @on_transmit.call(request.to_slice) rescue nil
      spawn { wait_ack }
    end

    protected def wait_ack : Nil
      @waiting = true
      select
      when @channel.receive
        @retries = 0
        @waiting = false
        @mutex.synchronize { @request_queue.shift }
      when timeout(@timeout)
        retransmit
      end
    end

    def retransmit : Nil
      @retries += 1

      if pending = @mutex.synchronize { @request_queue.first? }
        if @retries <= @max_retries
          perform_send pending
        else
          @waiting = false
          @connected = false
          @mutex.synchronize { @request_queue.clear }
          @on_state_change.call(false, KNX::ConnectionError::SubnetworkIssue) rescue nil
        end
      end
    end

    protected def next_sequence_no : UInt8
      @sequence = @sequence &+ 1_u8
    end

    # establish comms
    def connect : Nil
      return if connected?
      send KNX::ConnectRequest.new(@control)
    end

    # keep alive
    def query_state : Nil
      raise "not connected" unless connected?
      send KNX::ConnectStateRequest.new(@channel_id, @control)
    end

    # close comms
    def disconnect : Nil
      return unless connected?
      send KNX::DisconnectRequest.new(@channel_id, @control)
    end

    # perform an action / query
    def request(message : KNX::CEMI)
      raise "not connected" unless connected?
      send KNX::TunnelRequest.new(@channel_id, message)
    end

    # connected or disconnected state changed
    def on_state_change(&@on_state_change : Bool, KNX::ConnectionError ->)
    end

    # send some data to the remote
    def on_transmit(&@on_transmit : Bytes ->)
    end

    # a cEMI frame has been sent from the interface
    def on_message(&@on_message : KNX::CEMI ->)
    end

    # process incoming data
    def process(raw_data : Bytes)
      io = IO::Memory.new(raw_data)
      header = io.read_bytes(KNX::Header)
      io.rewind
      packet = case header.request_type
                when .connect_response?
                  io.read_bytes(KNX::ConnectResponse)
                when .connection_state_request?
                  io.read_bytes(KNX::ConnectStateRequest)
                when .connection_state_response?
                  io.read_bytes(KNX::ConnectStateResponse)
                when .disconnect_request?
                  io.read_bytes(KNX::DisconnectRequest)
                when .disconnect_response?
                  io.read_bytes(KNX::DisconnectResponse)
                when .tunnelling_request?
                  io.read_bytes(KNX::TunnelRequest)
                when .tunnelling_ack?
                  io.read_bytes(KNX::TunnelResponse)
                else
                  nil
                end

      process(packet) if packet
      packet
    end

    def process(packet : KNX::ConnectResponse)
      connected = packet.status.no_error?
      @channel_id = packet.channel_id
      @connected = connected
      @sequence = 0_u8
      @channel.send(nil) if @waiting
      @on_state_change.call(connected, packet.status)
      packet
    end

    def process(packet : KNX::ConnectStateRequest)
      if packet.channel_id == @channel_id
        # send no error
      else
        # send unknown channel id
      end
      packet
    end

    def process(packet : KNX::ConnectStateResponse)
      return packet if packet.channel_id != @channel_id

      @channel.send(nil) if @waiting
      connected = packet.status.no_error?
      if connected != @connected
        @connected = connected
        @on_state_change.call(connected, packet.status)
      end
      packet
    end

    def process(packet : KNX::DisconnectRequest)
      if packet.channel_id == @channel_id
        # send disconnect response
      end
      packet
    end

    def process(packet : KNX::DisconnectResponse)
      return packet if packet.channel_id != @channel_id

      @channel.send(nil) if @waiting
      if packet.status.no_error?
        @connected = false
        @on_state_change.call(false, packet.status)
      end
      packet
    end

    def process(packet : KNX::TunnelRequest)
      if packet.channel_id == @channel_id
        @on_transmit.call(KNX::TunnelResponse.new(@channel_id, packet.sequence).to_slice) rescue nil
        @on_message.call(packet.cemi)
      end
      packet
    end

    def process(packet : KNX::TunnelResponse)
      return packet if packet.channel_id != @channel_id
      @channel.send(nil) if @waiting
      # TODO:: process errors
      packet
    end
  end
end
