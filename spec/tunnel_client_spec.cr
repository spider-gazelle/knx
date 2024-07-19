require "./spec_helper"

describe KNX::TunnelClient do
  it "should handle state and basic protocol requirements" do
    client = KNX::TunnelClient.new(Socket::IPAddress.new("10.9.78.59", 48907))
    client.connected?.should eq false

    is_connected = nil
    last_error = nil
    last_trans = nil
    last_cemi = nil

    client.on_state_change do |connected, error|
      is_connected = connected
      last_error = error
    end
    client.on_transmit { |bytes| last_trans = bytes }
    client.on_message { |cemi| last_cemi = cemi }

    # check connection flow
    client.connect
    last_trans.should eq "06100205001a08010a094e3bbf0b08010a094e3bbf0b04040200".hexbytes
    client.process "0610020600143d0008010a094e510e5704041103".hexbytes

    is_connected.should eq true
    last_error.should eq KNX::ConnectionError::NoError
    client.waiting?.should eq false

    # check polling
    client.query_state
    last_trans.should eq "0610020700103d0008010a094e3bbf0b".hexbytes
    client.process "0610020800083d00".hexbytes
    is_connected.should eq true

    # check tunneling requests
    cemi = IO::Memory.new("1100b4e000000002010000".hexbytes).read_bytes(KNX::CEMI)
    client.request cemi

    last_trans.should eq "061004200015043d00001100b4e000000002010000".hexbytes
    client.process "06100421000a043d0000".hexbytes # ack received

    # receive the data from the request and we ack that
    client.process "061004200015043d00002e00b4e011030002010000".hexbytes
    last_trans.should eq "06100421000a043d0000".hexbytes

    cemi = IO::Memory.new("2e00b4e011030002010000".hexbytes).read_bytes(KNX::CEMI)
    last_cemi.as(KNX::CEMI).to_slice.should eq cemi.to_slice

    # receive more data from the request and we ack that
    client.process "061004200015043d01002900b4e011010002010040".hexbytes
    last_trans.should eq "06100421000a043d0100".hexbytes

    cemi = IO::Memory.new("2900b4e011010002010040".hexbytes).read_bytes(KNX::CEMI)
    last_cemi.as(KNX::CEMI).to_slice.should eq cemi.to_slice

    # disconnect from the interface
    client.disconnect
    last_trans.should eq "0610020900103d0008010a094e3bbf0b".hexbytes
    is_connected.should eq true

    client.process "0610020a00083d00".hexbytes
    is_connected.should eq false
  end

  it "should handle message queuing" do
    client = KNX::TunnelClient.new(Socket::IPAddress.new("10.9.78.59", 48907))
    client.connected?.should eq false

    is_connected = nil
    last_error = nil
    last_trans = nil
    last_cemi = nil

    client.on_state_change do |connected, error|
      is_connected = connected
      last_error = error
    end
    client.on_transmit { |bytes| last_trans = bytes }
    client.on_message { |cemi| last_cemi = cemi }

    # check connection flow
    client.connect
    last_trans.should eq "06100205001a08010a094e3bbf0b08010a094e3bbf0b04040200".hexbytes
    client.process "0610020600143d0008010a094e510e5704041103".hexbytes

    is_connected.should eq true
    last_error.should eq KNX::ConnectionError::NoError
    client.waiting?.should eq false

    # poll and tunnel before the ack is returned
    client.query_state
    cemi = IO::Memory.new("1100b4e000000002010000".hexbytes).read_bytes(KNX::CEMI)
    client.request cemi

    # check that query state is the last thing to be sent
    last_trans.should eq "0610020700103d0008010a094e3bbf0b".hexbytes
    client.queue_size.should eq 2

    # process the query ack
    client.process "0610020800083d00".hexbytes
    is_connected.should eq true

    # should then send the tunnel request
    last_trans.should eq "061004200015043d00001100b4e000000002010000".hexbytes

    client.queue_size.should eq 1
    client.process "06100421000a043d0000".hexbytes # ack received

    client.queue_size.should eq 0
  end

  it "should work with helper methods" do
    client = KNX::TunnelClient.new(
      Socket::IPAddress.new("10.9.78.59", 48907),
      knx: ::KNX.new(
        priority: :alarm,
        broadcast: true,
        no_repeat: true
      )
    )
    client.connected?.should eq false

    is_connected = nil
    last_error = nil
    last_trans = nil
    last_cemi = nil

    client.on_state_change do |connected, error|
      is_connected = connected
      last_error = error
    end
    client.on_transmit { |bytes| last_trans = bytes }
    client.on_message { |cemi| last_cemi = cemi }

    # check connection flow
    client.connect
    last_trans.should eq "06100205001a08010a094e3bbf0b08010a094e3bbf0b04040200".hexbytes
    client.process "0610020600143d0008010a094e510e5704041103".hexbytes

    is_connected.should eq true
    last_error.should eq KNX::ConnectionError::NoError
    client.waiting?.should eq false

    # make some requests
    client.action("0/0/2", true)
    last_trans.try(&.hexstring).should eq "061004200015043d00002900b4e000000002010081"
    client.process "0610020800083d00".hexbytes

    client.action("0/0/2", 2)
    last_trans.try(&.hexstring).should eq "061004200015043d01002900b4e000000002010082"
    client.process "0610020800083d00".hexbytes

    client.status("0/0/2")
    last_trans.try(&.hexstring).should eq "061004200015043d02001100b4e000000002010000"
  end
end
