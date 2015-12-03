module Sisimai
  # Sisimai::MSP - Base class for Sisimai::MSP::*, Mail Service Provider classes.
  module MSP
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/MSP.pm
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

      # MSP list
      # @return   [Array] MSP list with order
      def index
        return [
          'US::Google', 'US::Yahoo', 'US::Aol', 'US::Outlook', 'US::AmazonSES', 
          'US::SendGrid', 'US::Verizon', 'RU::MailRu', 'RU::Yandex', 'DE::GMX', 
          'US::Bigfoot', 'US::Facebook', 'US::Zoho', 'DE::EinsUndEins',
          'UK::MessageLabs', 'JP::EZweb', 'JP::KDDI', 'JP::Biglobe',
          'US::ReceivingSES',
        ]
      end

    end
  end
end
