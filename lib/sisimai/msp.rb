module Sisimai
  # Sisimai::MSP - Base class for Sisimai::MSP::*, Mail Service Provider classes.
  module MSP
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/MSP.pm
      require 'sisimai/skeleton'
      require 'sisimai/rfc5322'

      def INDICATORS;        return Sisimai::Skeleton.INDICATORS;     end
      def DELIVERYSTATUS;    return Sisimai::Skeleton.DELIVERYSTATUS; end
      def smtpagent(v = ''); return v.to_s.sub(/\ASisimai::/, '');    end

      # MSP list
      # @return   [Array] MSP list with order
      def index
        return [
          'US::Google', 'US::Yahoo', 'US::Aol', 'US::Outlook', 'US::AmazonSES',
          'US::SendGrid', 'US::GSuite', 'US::Verizon', 'RU::MailRu', 'RU::Yandex',
          'DE::GMX', 'US::Bigfoot', 'US::Facebook', 'US::Zoho', 'DE::EinsUndEins',
          'UK::MessageLabs', 'JP::EZweb', 'JP::KDDI', 'JP::Biglobe',
          'US::ReceivingSES', 'US::AmazonWorkMail', 'US::Office365',
        ]
      end

    end
  end
end
