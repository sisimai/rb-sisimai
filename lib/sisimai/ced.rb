module Sisimai
  # Sisimai::CED - Base class for Sisimai::CED::*: Cloud Email Delivery Services
  module CED
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/CED.pm
      require 'sisimai/skeleton'

      def INDICATORS;        return Sisimai::Skeleton.INDICATORS;     end
      def DELIVERYSTATUS;    return Sisimai::Skeleton.DELIVERYSTATUS; end
      def smtpagent(v = ''); return v.to_s.sub(/\ASisimai::/, '');    end

      # CED list
      # @return   [Array] CED list with order
      def index
        return ['US::AmazonSES', 'US::SendGrid']
      end

    end
  end
end

