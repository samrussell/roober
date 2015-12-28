require './lib/abstract_slice'
require './lib/ldp_message'
require 'stringio'

class LDPPDUPacked < AbstractSlice
  OFFSET_OF_LENGTH_FIELD = 2
  SIZE_OF_LENGTH_FIELD = 2
  BODY_LENGTH_DIFFERENCE = 0
  LENGTH_FIELD_UNPACK_STRING = 'S>'

  protected

  def initial_length
    OFFSET_OF_LENGTH_FIELD + SIZE_OF_LENGTH_FIELD
  end

  def remainder_length
    @initial.byteslice(OFFSET_OF_LENGTH_FIELD, SIZE_OF_LENGTH_FIELD).unpack(LENGTH_FIELD_UNPACK_STRING).first + BODY_LENGTH_DIFFERENCE
  end
end

class LDPPDU
  attr_reader :messages

  def initialize(messages)
    @messages = messages
  end

  def self.build_from_packet(raw_packet_data)
    # TODO really bad
    new(unpack_messages(raw_packet_data[4..-1]))
  end

  def self.unpack_messages(packed_messages)
    packed_message_stream = StringIO.new(packed_messages)
    message_slicer = IOSlicer.new(packed_message_stream, packed_messages.length, LDPMessagePacked)
    message_slicer.map do |packed_ldp_message|
      LDPMessage.build_from_packet(packed_ldp_message)
    end
  end
end
