module Sisimai
  # Sisimai::MTA - Base class for Sisimai::MTA::*
  module MTA
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/MTA.pm
      require 'sisimai/rfc5322'

      # Flags for position variable for
      # @return   [Hash] Position flag data
      # @private
      def INDICATORS
        return {
          'deliverystatus' => ( 1 << 1 ),
          'message-rfc822' => ( 1 << 2 ),
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
          'diagnosis'    => nil,  # The value of Diagnostic-Code header
          'recipient'    => nil,  # The value of Final-Recipient header
          'softbounce'   => nil,  # Soft bounce or not
          'feedbacktype' => nil,  # FeedBack Type
        }
      end

      # MTA list
      # @return   [Array] MTA list with order
      def index
        return [
          'Sendmail', 'Postfix', 'qmail', 'Exim', 'Courier', 'OpenSMTPD',
          'Exchange', 'MessagingServer', 'Domino', 'Notes', 'ApacheJames',
          'McAfee', 'MXLogic', 'MailFoundry', 'IMailServer', 'mFILTER',
          'Activehunter', 'InterScanMSS', 'SurfControl', 'MailMarshalSMTP',
          'X1', 'X2', 'X3', 'X4', 'X5', 'V5sendmail',
        ]
      end

    end
  end
end

