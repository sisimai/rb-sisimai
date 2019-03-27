module Sisimai
  module Order
    # Sisimai::Order::Email makes optimized order list which include MTA modules
    # to be loaded on first from MTA specific headers in the bounce mail headers
    # such as X-Failed-Recipients.
    # This module are called from only Sisimai::Message::Email.
    module Email
      # Imported from p5-Sisimail/lib/Sisimai/Order/Email.pm
      class << self
        require 'sisimai/bite/email'

        EngineOrder1 = [
          # These modules have many subject patterns or have MIME encoded subjects
          # which is hard to code as regular expression
          'Sisimai::Bite::Email::Exim',
          'Sisimai::Bite::Email::Exchange2003',
        ].freeze
        EngineOrder2 = [
          # These modules have no MTA specific header and did not listed in the
          # following subject header based regular expressions.
          'Sisimai::Bite::Email::Exchange2007',
          'Sisimai::Bite::Email::Facebook',
          'Sisimai::Bite::Email::KDDI',
        ].freeze
        EngineOrder3 = [
          # These modules have no MTA specific header but listed in the following
          # subject header based regular expressions.
          'Sisimai::Bite::Email::Sendmail',
          'Sisimai::Bite::Email::Postfix',
          'Sisimai::Bite::Email::Qmail',
          'Sisimai::Bite::Email::SendGrid',
          'Sisimai::Bite::Email::Courier',
          'Sisimai::Bite::Email::OpenSMTPD',
          'Sisimai::Bite::Email::Notes',
          'Sisimai::Bite::Email::MessagingServer',
          'Sisimai::Bite::Email::Domino',
          'Sisimai::Bite::Email::Bigfoot',
          'Sisimai::Bite::Email::EinsUndEins',
          'Sisimai::Bite::Email::MXLogic',
          'Sisimai::Bite::Email::IMailServer',
          'Sisimai::Bite::Email::X4',
        ].freeze
        EngineOrder4 = [
          # These modules have no MTA specific headers and there are few samples or
          # too old MTA
          'Sisimai::Bite::Email::Verizon',
          'Sisimai::Bite::Email::InterScanMSS',
          'Sisimai::Bite::Email::MailFoundry',
          'Sisimai::Bite::Email::ApacheJames',
          'Sisimai::Bite::Email::Biglobe',
          'Sisimai::Bite::Email::EZweb',
          'Sisimai::Bite::Email::X5',
          'Sisimai::Bite::Email::X3',
          'Sisimai::Bite::Email::X2',
          'Sisimai::Bite::Email::X1',
          'Sisimai::Bite::Email::V5sendmail',
        ].freeze
        EngineOrder5 = [
          # These modules have one or more MTA specific headers but other headers
          # also required for detecting MTA name
          'Sisimai::Bite::Email::Outlook',
          'Sisimai::Bite::Email::MailRu',
          'Sisimai::Bite::Email::MessageLabs',
          'Sisimai::Bite::Email::MailMarshalSMTP',
          'Sisimai::Bite::Email::MFILTER',
          'Sisimai::Bite::Email::Google',
        ].freeze
        EngineOrder9 = [
          # These modules have one or more MTA specific headers
          'Sisimai::Bite::Email::Aol',
          'Sisimai::Bite::Email::Yahoo',
          'Sisimai::Bite::Email::AmazonSES',
          'Sisimai::Bite::Email::GMX',
          'Sisimai::Bite::Email::Yandex',
          'Sisimai::Bite::Email::Office365',
          'Sisimai::Bite::Email::ReceivingSES',
          'Sisimai::Bite::Email::AmazonWorkMail',
          'Sisimai::Bite::Email::Zoho',
          'Sisimai::Bite::Email::McAfee',
          'Sisimai::Bite::Email::Activehunter',
          'Sisimai::Bite::Email::SurfControl',
        ].freeze

        # This variable don't hold MTA name which have one or more MTA specific
        # header such as X-AWS-Outgoing, X-Yandex-Uniq.
        PatternTable = {
          'subject' => {
            'delivery' => [
              'Sisimai::Bite::Email::Exim',
              'Sisimai::Bite::Email::Outlook',
              'Sisimai::Bite::Email::Courier',
              'Sisimai::Bite::Email::Domino',
              'Sisimai::Bite::Email::OpenSMTPD',
              'Sisimai::Bite::Email::EinsUndEins',
              'Sisimai::Bite::Email::InterScanMSS',
              'Sisimai::Bite::Email::MailFoundry',
              'Sisimai::Bite::Email::X4',
              'Sisimai::Bite::Email::X3',
              'Sisimai::Bite::Email::X2',
              'Sisimai::Bite::Email::Google',
            ],
            'noti' => [
              'Sisimai::Bite::Email::Sendmail',
              'Sisimai::Bite::Email::Qmail',
              'Sisimai::Bite::Email::Outlook',
              'Sisimai::Bite::Email::Courier',
              'Sisimai::Bite::Email::MessagingServer',
              'Sisimai::Bite::Email::OpenSMTPD',
              'Sisimai::Bite::Email::X4',
              'Sisimai::Bite::Email::X3',
              'Sisimai::Bite::Email::MFILTER',
              'Sisimai::Bite::Email::Google',
            ],
            'return' => [
              'Sisimai::Bite::Email::Postfix',
              'Sisimai::Bite::Email::Sendmail',
              'Sisimai::Bite::Email::SendGrid',
              'Sisimai::Bite::Email::Bigfoot',
              'Sisimai::Bite::Email::EinsUndEins',
              'Sisimai::Bite::Email::X1',
              'Sisimai::Bite::Email::Biglobe',
              'Sisimai::Bite::Email::V5sendmail',
            ],
            'undeliver' => [
              'Sisimai::Bite::Email::Postfix',
              'Sisimai::Bite::Email::Office365',
              'Sisimai::Bite::Email::Exchange2007',
              'Sisimai::Bite::Email::Exchange2003',
              'Sisimai::Bite::Email::SendGrid',
              'Sisimai::Bite::Email::Notes',
              'Sisimai::Bite::Email::Verizon',
              'Sisimai::Bite::Email::IMailServer',
              'Sisimai::Bite::Email::MailMarshalSMTP',
            ],
            'failure' => [
              'Sisimai::Bite::Email::Qmail',
              'Sisimai::Bite::Email::Outlook',
              'Sisimai::Bite::Email::MailRu',
              'Sisimai::Bite::Email::Domino',
              'Sisimai::Bite::Email::X4',
              'Sisimai::Bite::Email::X2',
              'Sisimai::Bite::Email::MFILTER',
              'Sisimai::Bite::Email::Google',
            ],
            'warning' => [
              'Sisimai::Bite::Email::Postfix',
              'Sisimai::Bite::Email::Sendmail',
              'Sisimai::Bite::Email::Exim',
            ],
          },
        }.freeze
        Skips = { 'return-path' => 1, 'x-mailer' => 1 }.freeze

        # @abstract Make default order of MTA modules to be loaded
        # @return   [Array] Default order list of MTA modules
        def default
          return Sisimai::Bite::Email.index.map { |e| 'Sisimai::Bite::Email::' << e }
        end

        # @abstract Get regular expression patterns for specified field
        # @param    [String] group  Group name for "ORDER BY"
        # @return   [Hash]          Pattern table for the group
        def by(group = '')
          return {} if group.empty?
          return PatternTable[group] if PatternTable.key?(group)
          return {}
        end

        # @abstract Make MTA module list as a spare
        # @return   [Array] Ordered module list
        def another
          rv = []
          [EngineOrder1, EngineOrder2, EngineOrder3, EngineOrder4, EngineOrder5, EngineOrder9].each do |e|
            rv += e
          end
          return rv
        end

        # @abstract Make email header list in each MTA module
        # @return   [Hash] Header list to be parsed
        def headers
          order = Sisimai::Bite::Email.heads.map { |e| 'Sisimai::Bite::Email::' << e }
          table = {}

          while e = order.shift do
            # Load email headers from each MTA module
            require e.gsub('::', '/').downcase

            Module.const_get(e).headerlist.each do |v|
              # Get header name which required each MTA module
              next if Skips.key?(v)
              table[v] ||= []
              table[v] << e
            end
          end
          return table
        end

      end
    end
  end
end

