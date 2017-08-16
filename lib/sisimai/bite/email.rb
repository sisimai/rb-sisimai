module Sisimai
  # Sisimai::Bite::Email- Base class for Sisimai::Bite::Email::*
  module Bite
    module Email
      class << self
        # Imported from p5-Sisimail/lib/Sisimai/Bite/Email.pm
        require 'sisimai/bite'
        require 'sisimai/rfc5322'

        # @abstract Flags for position variable
        # @return   [Hash] Position flag data
        # @private
        def INDICATORS
          return {
            :'deliverystatus' => (1 << 1),
            :'message-rfc822' => (1 << 2),
          }
        end
        def headerlist; return []; end
        def pattern;    return []; end

        # @abstract MTA list
        # @return   [Array] MTA list with order
        def index
          return ['Sendmail']
#         return %w|
#           Sendmail Postfix qmail Exim Courier OpenSMTPD Exchange2007 Exchange2003
#           Google Yahoo GSuite Aol Outlook Office365 SendGrid AmazonSES MailRu
#           Yandex MessagingServer Domino Notes ReceivingSES AmazonWorkMail Verizon
#           GMX Bigfoot Facebook Zoho EinsUndEins MessageLabs EZweb KDDI Biglobe
#           ApacheJames McAfee MXLogic MailFoundry IMailServer 
#           mFILTER Activehunter InterScanMSS SurfControl MailMarshalSMTP
#           X1 X2 X3 X4 X5 V5sendmail 
#         |
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
        def scan; return nil; end

      end
    end
  end
end

