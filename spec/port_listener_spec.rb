require 'spec_helper'
require './lib/port_listener'
require 'socket'

describe PortListener do
  let(:port_listener) { PortListener.new(179) }

  describe '#handle_client' do
    let(:mock_tcp_server) { instance_double("TCPServer") }

    it 'reads data' do
    end
  end
end
