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
  UNPACK_STRING = 'S>S>L>S>a*'

  attr_reader :version, :lsr_id, :label_space_id, :messages

  def initialize(version, lsr_id, label_space_id, messages)
    @version = version
    @lsr_id = lsr_id
    @label_space_id = label_space_id
    @messages = messages
  end

  def self.build_from_packet(raw_packet_data)
    # TODO really bad
    version, length, lsr_id, label_space_id, data = raw_packet_data.unpack(UNPACK_STRING)
    new(version, lsr_id, label_space_id, unpack_messages(data))
  end

  def self.unpack_messages(packed_messages)
    packed_message_stream = StringIO.new(packed_messages)
    message_slicer = IOSlicer.new(packed_message_stream, packed_messages.length, LDPMessagePacked)
    message_slicer.map do |packed_ldp_message|
      message = LDPMessage.build_from_packet(packed_ldp_message)
      puts "Message: #{message.inspect}"
      message
    end
  end
end
