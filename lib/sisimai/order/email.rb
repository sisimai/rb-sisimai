module Sisimai
  # Sisimai::Order::Email makes optimized order list which include MTA modules
  # to be loaded on first from MTA specific headers in the bounce mail headers
  # such as X-Failed-Recipients.
  # This module are called from only Sisimai::Message::Email.
  module Order
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
          'Sisimai::Bite::Email::Qmail',
          'Sisimai::Bite::Email::Notes',
          'Sisimai::Bite::Email::MessagingServer',
          'Sisimai::Bite::Email::Domino',
          'Sisimai::Bite::Email::EinsUndEins',
          'Sisimai::Bite::Email::OpenSMTPD',
          'Sisimai::Bite::Email::MXLogic',
          'Sisimai::Bite::Email::Postfix',
          'Sisimai::Bite::Email::Sendmail',
          'Sisimai::Bite::Email::Courier',
          'Sisimai::Bite::Email::IMailServer',
          'Sisimai::Bite::Email::SendGrid',
          'Sisimai::Bite::Email::Bigfoot',
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
          'Sisimai::Bite::Email::Google',
          'Sisimai::Bite::Email::Outlook',
          'Sisimai::Bite::Email::MailRu',
          'Sisimai::Bite::Email::MessageLabs',
          'Sisimai::Bite::Email::MailMarshalSMTP',
          'Sisimai::Bite::Email::MFILTER',
        ].freeze
        EngineOrder9 = [
          # These modules have one or more MTA specific headers
          'Sisimai::Bite::Email::Aol',
          'Sisimai::Bite::Email::Yahoo',
          'Sisimai::Bite::Email::AmazonSES',
          'Sisimai::Bite::Email::GMX',
          'Sisimai::Bite::Email::Yandex',
          'Sisimai::Bite::Email::ReceivingSES',
          'Sisimai::Bite::Email::Office365',
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
            %r/delivery/i => [
              'Sisimai::Bite::Email::Exim',
              'Sisimai::Bite::Email::Courier',
              'Sisimai::Bite::Email::Google',
              'Sisimai::Bite::Email::Outlook',
              'Sisimai::Bite::Email::Domino',
              'Sisimai::Bite::Email::OpenSMTPD',
              'Sisimai::Bite::Email::EinsUndEins',
              'Sisimai::Bite::Email::InterScanMSS',
              'Sisimai::Bite::Email::MailFoundry',
              'Sisimai::Bite::Email::X4',
              'Sisimai::Bite::Email::X3',
              'Sisimai::Bite::Email::X2',
            ],
            %r/noti(?:ce|fi)/i => [
              'Sisimai::Bite::Email::Qmail',
              'Sisimai::Bite::Email::Sendmail',
              'Sisimai::Bite::Email::Google',
              'Sisimai::Bite::Email::Outlook',
              'Sisimai::Bite::Email::Courier',
              'Sisimai::Bite::Email::MessagingServer',
              'Sisimai::Bite::Email::OpenSMTPD',
              'Sisimai::Bite::Email::X4',
              'Sisimai::Bite::Email::X3',
              'Sisimai::Bite::Email::MFILTER',
            ],
            %r/return/i => [
              'Sisimai::Bite::Email::Postfix',
              'Sisimai::Bite::Email::Sendmail',
              'Sisimai::Bite::Email::SendGrid',
              'Sisimai::Bite::Email::Bigfoot',
              'Sisimai::Bite::Email::X1',
              'Sisimai::Bite::Email::EinsUndEins',
              'Sisimai::Bite::Email::Biglobe',
              'Sisimai::Bite::Email::V5sendmail',
            ],
            %r/undeliver/i => [
              'Sisimai::Bite::Email::Postfix',
              'Sisimai::Bite::Email::Exchange2007',
              'Sisimai::Bite::Email::Exchange2003',
              'Sisimai::Bite::Email::Notes',
              'Sisimai::Bite::Email::Office365',
              'Sisimai::Bite::Email::Verizon',
              'Sisimai::Bite::Email::SendGrid',
              'Sisimai::Bite::Email::IMailServer',
              'Sisimai::Bite::Email::MailMarshalSMTP',
            ],
            %r/failure/i => [
              'Sisimai::Bite::Email::Qmail',
              'Sisimai::Bite::Email::Domino',
              'Sisimai::Bite::Email::Google',
              'Sisimai::Bite::Email::Outlook',
              'Sisimai::Bite::Email::MailRu',
              'Sisimai::Bite::Email::X4',
              'Sisimai::Bite::Email::X2',
              'Sisimai::Bite::Email::MFILTER',
            ],
            %r/warning/i => [
              'Sisimai::Bite::Email::Postfix',
              'Sisimai::Bite::Email::Sendmail',
              'Sisimai::Bite::Email::Exim',
            ],
          },
        }.freeze

        make_default_order = lambda do
          # Make default order of MTA modules to be loaded
          rv = []
          begin
            rv.concat(Sisimai::Bite::Email.index.map { |e| 'Sisimai::Bite::Email::' + e })
          rescue
            # Failed to load an MTA module
            next
          end
          return rv
        end
        DefaultOrder = make_default_order.call

        # @abstract Make default order of MTA modules to be loaded
        # @return   [Array] Default order list of MTA modules
        def default
          return DefaultOrder
        end

        # @abstract Get regular expression patterns for specified field
        # @param    [String] group  Group name for "ORDER BY"
        # @return   [Hash]          Pattern table for the group
        def by(group = '')
          return {} unless group.size > 0
          return PatternTable[group] if PatternTable.key?(group)
          return {}
        end

        # @abstract Make MTA module list as a spare
        # @return   [Array] Ordered module list
        def another
          rv = []
          rv.concat(EngineOrder1)
          rv.concat(EngineOrder2)
          rv.concat(EngineOrder3)
          rv.concat(EngineOrder4)
          rv.concat(EngineOrder5)
          rv.concat(EngineOrder9)
          return rv
        end

        # @abstract Make email header list in each MTA module
        # @return   [Hash] Header list to be parsed
        def headers
          order = self.default
          table = {}
          skips = { 'return-path' => 1, 'x-mailer' => 1 }

          order.each do |e|
            # Load email headers from each MTA module
            begin
              require e.gsub('::', '/').downcase
            rescue LoadError
              warn ' ***warning: Failed to load ' + e
              next
            end

            Module.const_get(e).headerlist.each do |v|
              # Get header name which required each MTA module
              q = v.downcase
              next if skips.key?(q)
              table[q]  ||= {}
              table[q][e] = 1
            end
          end
          return table
        end

      end
    end
  end
end

