module Sisimai
  # Sisimai::CED - Base class for Sisimai::CED::*: Cloud Email Delivery Services
  module CED
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/CED.pm
      require 'sisimai/skeleton'

      def INDICATORS
        warn ' ***warning: Sisimai::CED->INDICATORS has been moved to Sisimai::Bite::Email->INDICATORS'
        return Sisimai::Skeleton.INDICATORS
      end

      def DELIVERYSTATUS
        warn ' ***warning: Sisimai::CED->DELIVERYSTATUS has been moved to Sisimai::Bite->DELIVERYSTATUS'
        return Sisimai::Skeleton.DELIVERYSTATUS
      end

      def smtpagent(v = '')
        warn ' ***warning: Sisimai::CED->smtpagent has been moved to Sisimai::Bite->smtpagent'
        return v.to_s.sub(/\ASisimai::/, '')
      end

      def description
        warn ' ***warning: Sisimai::CED->description has been moved to Sisimai::Bite->description'
        return ''
      end

      def headerlist
        warn ' ***warning: Sisimai::CED->headerlist has been moved to Sisimai::Bite::Email->headerlist'
        return []
      end

      def pattern
        warn ' ***warning: Sisimai::CED->pattern has been moved to Sisimai::Bite::Email->pattern'
        return {}
      end

      # CED list
      # @return   [Array] CED list with order
      def index
        warn ' ***warning: Sisimai::CED->index has been moved to Sisimai::Bite::Email->index'
        return ['US::AmazonSES', 'US::SendGrid']
      end

    end
  end
end

