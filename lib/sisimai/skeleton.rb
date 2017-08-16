module Sisimai
  # Sisimai::Skeleton - Class for basic data structure of Sisimai
  module Skeleton
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Skeleton.pm

      # Flags for position variables
      # @return   [Hash] Position flag data
      # @private
      def INDICATORS
        return {
          :'deliverystatus' => (1 << 1),
          :'message-rfc822' => (1 << 2),
        }
      end

      # Data structure for parsed bounce messages
      # @return [Hash] Data structure for delivery status
      # @private
      def DELIVERYSTATUS
        return {
          'spec'         => nil,  # Protocl specification
          'date'         => nil,  # The value of Last-Attempt-Date header
          'rhost'        => nil,  # The value of Remote-MTA header
          'lhost'        => nil,  # The value of Received-From-MTA header
          'alias'        => nil,  # The value of alias entry(RHS)
          'agent'        => nil,  # MTA name
          'action'       => nil,  # The value of Action header
          'status'       => nil,  # The value of Status header
          'reason'       => nil,  # Temporary reason of bounce
          'command'      => nil,  # SMTP command in the message body
          'replycode'    => nil,  # SMTP Reply code
          'diagnosis'    => nil,  # The value of Diagnostic-Code header
          'recipient'    => nil,  # The value of Final-Recipient header
          'softbounce'   => nil,  # Soft bounce or not
          'feedbacktype' => nil,  # Feedback Type
        }
      end

    end
  end
end

