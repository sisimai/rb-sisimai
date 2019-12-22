module Sisimai
  # Sisimai::Order - Parent class for making optimized order list for calling
  # MTA modules
  module Order
    # Imported from p5-Sisimail/lib/Sisimai/Order.pm
    class << self
      require 'sisimai/lhost'

      OrderE1 = [
        # These modules have many subject patterns or have MIME encoded subjects
        # which is hard to code as regular expression
        'Sisimai::Lhost::Exim',
        'Sisimai::Lhost::Exchange2003',
      ].freeze
      OrderE2 = [
        # These modules have no MTA specific header and did not listed in the
        # following subject header based regular expressions.
        'Sisimai::Lhost::Exchange2007',
        'Sisimai::Lhost::Facebook',
        'Sisimai::Lhost::KDDI',
      ].freeze
      OrderE3 = [
        # These modules have no MTA specific header but listed in the following
        # subject header based regular expressions.
        'Sisimai::Lhost::Sendmail',
        'Sisimai::Lhost::Postfix',
        'Sisimai::Lhost::Qmail',
        'Sisimai::Lhost::SendGrid',
        'Sisimai::Lhost::Courier',
        'Sisimai::Lhost::OpenSMTPD',
        'Sisimai::Lhost::Notes',
        'Sisimai::Lhost::MessagingServer',
        'Sisimai::Lhost::Domino',
        'Sisimai::Lhost::Bigfoot',
        'Sisimai::Lhost::EinsUndEins',
        'Sisimai::Lhost::MXLogic',
        'Sisimai::Lhost::Amavis',
        'Sisimai::Lhost::IMailServer',
        'Sisimai::Lhost::X4',
      ].freeze
      OrderE4 = [
        # These modules have no MTA specific headers and there are few samples or
        # too old MTA
        'Sisimai::Lhost::Verizon',
        'Sisimai::Lhost::InterScanMSS',
        'Sisimai::Lhost::MailFoundry',
        'Sisimai::Lhost::ApacheJames',
        'Sisimai::Lhost::Biglobe',
        'Sisimai::Lhost::EZweb',
        'Sisimai::Lhost::X5',
        'Sisimai::Lhost::X3',
        'Sisimai::Lhost::X2',
        'Sisimai::Lhost::X1',
        'Sisimai::Lhost::V5sendmail',
      ].freeze
      OrderE5 = [
        # These modules have one or more MTA specific headers but other headers
        # also required for detecting MTA name
        'Sisimai::Lhost::Outlook',
        'Sisimai::Lhost::MailRu',
        'Sisimai::Lhost::MessageLabs',
        'Sisimai::Lhost::MailMarshalSMTP',
        'Sisimai::Lhost::MFILTER',
        'Sisimai::Lhost::Google',
      ].freeze
      OrderE9 = [
        # These modules have one or more MTA specific headers
        'Sisimai::Lhost::Aol',
        'Sisimai::Lhost::Yahoo',
        'Sisimai::Lhost::AmazonSES',
        'Sisimai::Lhost::GMX',
        'Sisimai::Lhost::Yandex',
        'Sisimai::Lhost::Office365',
        'Sisimai::Lhost::ReceivingSES',
        'Sisimai::Lhost::AmazonWorkMail',
        'Sisimai::Lhost::Zoho',
        'Sisimai::Lhost::McAfee',
        'Sisimai::Lhost::Activehunter',
        'Sisimai::Lhost::SurfControl',
      ].freeze

      # This variable don't hold MTA name which have one or more MTA specific
      # header such as X-AWS-Outgoing, X-Yandex-Uniq.
      Pattern = {
        'subject' => {
          'delivery' => [
            'Sisimai::Lhost::Exim',
            'Sisimai::Lhost::Outlook',
            'Sisimai::Lhost::Courier',
            'Sisimai::Lhost::Domino',
            'Sisimai::Lhost::OpenSMTPD',
            'Sisimai::Lhost::EinsUndEins',
            'Sisimai::Lhost::InterScanMSS',
            'Sisimai::Lhost::MailFoundry',
            'Sisimai::Lhost::X4',
            'Sisimai::Lhost::X3',
            'Sisimai::Lhost::X2',
            'Sisimai::Lhost::Google',
          ],
          'noti' => [
            'Sisimai::Lhost::Sendmail',
            'Sisimai::Lhost::Qmail',
            'Sisimai::Lhost::Outlook',
            'Sisimai::Lhost::Courier',
            'Sisimai::Lhost::MessagingServer',
            'Sisimai::Lhost::OpenSMTPD',
            'Sisimai::Lhost::X4',
            'Sisimai::Lhost::X3',
            'Sisimai::Lhost::MFILTER',
            'Sisimai::Lhost::Google',
          ],
          'return' => [
            'Sisimai::Lhost::Postfix',
            'Sisimai::Lhost::Sendmail',
            'Sisimai::Lhost::SendGrid',
            'Sisimai::Lhost::Bigfoot',
            'Sisimai::Lhost::EinsUndEins',
            'Sisimai::Lhost::X1',
            'Sisimai::Lhost::Biglobe',
            'Sisimai::Lhost::V5sendmail',
          ],
          'undeliver' => [
            'Sisimai::Lhost::Postfix',
            'Sisimai::Lhost::Office365',
            'Sisimai::Lhost::Exchange2007',
            'Sisimai::Lhost::Exchange2003',
            'Sisimai::Lhost::SendGrid',
            'Sisimai::Lhost::Notes',
            'Sisimai::Lhost::Verizon',
            'Sisimai::Lhost::Amavis',
            'Sisimai::Lhost::IMailServer',
            'Sisimai::Lhost::MailMarshalSMTP',
          ],
          'failure' => [
            'Sisimai::Lhost::Qmail',
            'Sisimai::Lhost::Outlook',
            'Sisimai::Lhost::MailRu',
            'Sisimai::Lhost::Domino',
            'Sisimai::Lhost::X4',
            'Sisimai::Lhost::X2',
            'Sisimai::Lhost::MFILTER',
            'Sisimai::Lhost::Google',
          ],
          'warning' => [
            'Sisimai::Lhost::Postfix',
            'Sisimai::Lhost::Sendmail',
            'Sisimai::Lhost::Exim',
          ],
        },
      }.freeze
      Skips   = { 'return-path' => 1, 'x-mailer' => 1 }.freeze

      # @abstract Check headers for detecting MTA module and returns the order
      #           of modules
      # @param    [Hash] heads   Email header data
      # @return   [Array]        Order of MTA modules
      # @since    v4.25.4
      def make(heads = {})
        return [] unless heads['subject']

        # Try to match the value of "Subject" with patterns generated by
        # Sisimai::Order->by('subject') method
        order = []
        title = heads['subject'].downcase
        Subject.each_key do |e|
          # Get MTA list from the subject header
          next unless title.include?(e)
          order = Subject[e]
          break
        end

        return order
      end

      # @abstract Get regular expression patterns for specified field
      # @param    [String] group  Group name for "ORDER BY"
      # @return   [Hash]          Pattern table for the group
      def by(group = '')
        return {} if group.empty?
        return Pattern[group] if Pattern.key?(group)
        return {}
      end
      Subject = Sisimai::Order.by('subject').freeze

      # @abstract Make default order of MTA modules to be loaded
      # @return   [Array] Default order list of MTA modules
      def default
        return Sisimai::Lhost.index.map { |e| 'Sisimai::Lhost::' << e }
      end

      # @abstract Make MTA module list as a spare
      # @return   [Array] Ordered module list
      def another
        rv = []
        [OrderE1, OrderE2, OrderE3, OrderE4, OrderE5, OrderE9].each do |e|
          rv += e
        end
        return rv
      end

      # @abstract Make email header list in each MTA module
      # @return   [Hash] Header list to be parsed
      def headers
        order = Sisimai::Lhost.heads.map { |e| 'Sisimai::Lhost::' << e }
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
