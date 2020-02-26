module Sisimai
  # Sisimai::Lhost - Base class for Sisimai::Lhost::*
  module Lhost
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Lhost.pm
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

      # @abstract Flags for position variable
      # @return   [Hash] Position flag data
      # @private
      def INDICATORS
        return {
          :'deliverystatus' => (1 << 1),
          :'message-rfc822' => (1 << 2),
        }
      end

      def smtpagent(v = '')
        return v.to_s.sub(/\ASisimai::Lhost::/, 'Email::')
      end
      def description; return ''; end

      # @abstract MTA list
      # @return   [Array] MTA list with order
      def index
        return %w[
          Activehunter Amavis AmazonSES AmazonWorkMail Aol ApacheJames Barracuda
          Bigfoot Biglobe Courier Domino EZweb EinsUndEins Exchange2003 Exchange2007
          Exim FML Facebook GMX GSuite Google IMailServer InterScanMSS KDDI MXLogic
          MailFoundry MailMarshalSMTP MailRu McAfee MessageLabs MessagingServer Notes
          Office365 OpenSMTPD Outlook Postfix ReceivingSES SendGrid Sendmail
          SurfControl V5sendmail Verizon X1 X2 X3 X4 X5 Yahoo Yandex Zoho MFILTER Qmail
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
        index.each { |e| table['Sisimai::Lhost::' << e] = 'sisimai/lhost/' << e.downcase }
        return table
      end

      # @abstract Parse bounce messages
      # @param         [Hash] mhead       Message header of a bounce email
      # @options mhead [String] from      From header
      # @options mhead [String] date      Date header
      # @options mhead [String] subject   Subject header
      # @options mhead [Array]  received  Received headers
      # @options mhead [String] others    Other required headers
      # @param         [String] mbody     Message body of a bounce email
      # @return        [Hash, Nil]        Bounce data list and message/rfc822
      #                                   part or nil if it failed to parse or
      #                                   the arguments are missing
      def make; return nil; end
    end
  end
end

