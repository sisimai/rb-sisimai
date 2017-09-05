module Sisimai
  # Sisimai::Bite - Base class for Sisimai::Bite::*
  module Bite
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite.pm
      require 'sisimai/rfc5322'

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
          'agent'        => nil,  # MTA module name
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

      def smtpagent(v = ''); return v.to_s.sub(/\ASisimai::Bite::/, ''); end
      def description; return ''; end

    end
  end
end


