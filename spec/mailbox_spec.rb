require 'spec_helper'
require './lib/mailbox'
require './lib/bgp_message'
require 'stringio'

describe Mailbox do
  let(:fake_socket) { StringIO.new }
  let(:fake_message) { instance_double('BGPMessage') }
  let(:fake_packed_message) { 'abc123' }
  subject(:mailbox) { Mailbox.new(fake_socket) }

  before do
    allow(fake_message).to receive(:message_type).and_return(1)
  end

  describe '#send_message' do
    it 'sends data out the socket' do
      expect(fake_message).to receive(:pack).and_return(fake_packed_message)
      expect(fake_socket).to receive(:write).with(fake_packed_message)

      mailbox.send_message(fake_message)
    end
  end
end
