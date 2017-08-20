module Sisimai
  # Sisimai::MTA - Base class for Sisimai::MTA::*
  module MTA
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/MTA.pm
      require 'sisimai/skeleton'
      require 'sisimai/rfc5322'

      def INDICATORS
        warn ' ***warning: Sisimai::MTA->INDICATORS has been moved to Sisimai::Bite::Email->INDICATORS'
        return Sisimai::Skeleton.INDICATORS
      end

      def DELIVERYSTATUS
        warn ' ***warning: Sisimai::MTA->DELIVERYSTATUS has been moved to Sisimai::Bite->DELIVERYSTATUS'
        return Sisimai::Skeleton.DELIVERYSTATUS
      end

      def smtpagent(v = '')
        warn ' ***warning: Sisimai::MTA->smtpagent has been moved to Sisimai::Bite->smtpagent'
        return v.to_s.sub(/\ASisimai::/, '')
      end

      # MTA list
      # @return   [Array] MTA list with order
      def index
        warn ' ***warning: Sisimai::MTA->index has been moved to Sisimai::Bite::Email->index'
        return %w|
          Sendmail Postfix Qmail Exim Courier OpenSMTPD Exchange2007 Exchange2003
          MessagingServer Domino Notes ApacheJames McAfee MXLogic MailFoundry
          IMailServer MFILTER Activehunter InterScanMSS SurfControl MailMarshalSMTP
          X1 X2 X3 X4 X5 V5sendmail
        |
      end

    end
  end
end

