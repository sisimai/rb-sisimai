module Sisimai
  # Sisimai::Lhost - Base class for Sisimai::Lhost::*
  module Lhost
    class << self
      require 'sisimai/rfc5322'

      # @abstract Returns the data structure for decoded bounce messages
      # @return [Hash] Data structure for delivery status
      # @private
      def DELIVERYSTATUS
        return {
          'spec'         => "",  # Protocl specification
          'date'         => "",  # The value of Last-Attempt-Date header
          'rhost'        => "",  # The value of Remote-MTA header
          'lhost'        => "",  # The value of Received-From-MTA header
          'alias'        => "",  # The value of alias entry(RHS)
          'agent'        => "",  # MTA module name
          'action'       => "",  # The value of Action header
          'status'       => "",  # The value of Status header
          'reason'       => "",  # Temporary reason of bounce
          'command'      => "",  # SMTP command in the message body
          'replycode'    => "",  # SMTP Reply code
          'diagnosis'    => "",  # The value of Diagnostic-Code header
          'recipient'    => "",  # The value of Final-Recipient header
          'feedbacktype' => "",  # Feedback Type
        }
      end

      # @abstract Flags for position variable
      # @return   [Hash] Position flag data
      # @private
      def INDICATORS
        return {
          :'deliverystatus' => (1 << 1),
          :'message-rfc822' => (1 << 2),
        }
      end

      # @abstract MTA list
      # @return   [Array] MTA list with order
      def index
        return %w[
          Activehunter AmazonSES ApacheJames Biglobe Courier Domino DragonFly EZweb EinsUndEins Exchange2003
          Exchange2007 Exim FML GMX GoogleWorkspace GoogleGroups Gmail IMailServer InterScanMSS KDDI
          MailFoundry MailMarshalSMTP MessagingServer Notes OpenSMTPD Postfix Sendmail V5sendmail
          Verizon X1 X2 X3 X6 Zoho MFILTER Qmail
        ]
      end

      # @abstract Returns Sisimai::Lhost::* module path table
      # @return [Hash] Module path table
      # @since  v4.25.6
      def path
        index = Sisimai::Lhost.index
        table = {
          'Sisimai::ARF'     => 'sisimai/arf',
          'Sisimai::RFC3464' => 'sisimai/rfc3464',
          'Sisimai::RFC3834' => 'sisimai/rfc3834',
        }
        index.each { |e| table["Sisimai::Lhost::#{e}"] = "sisimai/lhost/#{e.downcase}" }
        return table
      end

      # @abstract decode bounce messages
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire; return nil; end
      def description; return ''; end
    end
  end
end

