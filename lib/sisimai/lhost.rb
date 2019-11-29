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
      def headerlist;  return []; end
      def removedat;   return 'v4.25.5'; end # This method will be removed at the future release of Sisimai

      # @abstract MTA list
      # @return   [Array] MTA list with order
      def index
        return %w[
          Sendmail Postfix Qmail Exim Courier OpenSMTPD Office365 Outlook
          Exchange2007 Exchange2003 Yahoo GSuite Aol SendGrid AmazonSES MailRu
          Yandex MessagingServer Domino Notes ReceivingSES AmazonWorkMail Verizon
          GMX Bigfoot Facebook Zoho EinsUndEins MessageLabs EZweb KDDI Biglobe
          Amavis ApacheJames McAfee MXLogic MailFoundry IMailServer
          MFILTER Activehunter InterScanMSS SurfControl MailMarshalSMTP
          X1 X2 X3 X4 X5 V5sendmail FML Google]
      end

      # @abstract MTA list which have one or more extra headers
      # @return   [Array] MTA list (have extra headers)
      def heads
        return %w[
          Exim Office365 Outlook Exchange2007 Exchange2003 GSuite SendGrid
          AmazonSES ReceivingSES AmazonWorkMail Aol GMX MailRu MessageLabs Yahoo
          Yandex Zoho EinsUndEins MXLogic McAfee MFILTER EZweb Activehunter IMailServer
          SurfControl FML Google
        ]
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

      # @abstract Print warnings about an obsoleted method. This method will be
      #           removed at the future release of Sisimai
      # @until    v4.25.5
      def warn(whois = '', useit = nil)
        label = ' ***warning:'
        methodname = caller[0][/`.*'/][1..-2]
        messageset = sprintf("%s %s.%s is marked as obsoleted", label, whois, methodname)

        useit ||= methodname
        messageset << sprintf(" and will be removed at %s.", removedat)
        messageset << sprintf(" Use %s.%s instead.\n", self.name, useit) if useit != 'gone'
        Kernel.warn messageset
      end
    end
  end
end
