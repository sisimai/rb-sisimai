module Sisimai
  # Sisimai::RFC1894 DSN field defined in RFC3464 (obsoletes RFC1894)
  module RFC1894
    class << self
      require 'sisimai/string'
      FieldNames = [
        # https://tools.ietf.org/html/rfc3464#section-2.2
        #   Some fields of a DSN apply to all of the delivery attempts described by that DSN. At
        #   most, these fields may appear once in any DSN. These fields are used to correlate the
        #   DSN with the original message transaction and to provide additional information which
        #   may be useful to gateways.
        #
        #   The following fields (not defined in RFC 3464) are used in Sisimai
        #     - X-Original-Message-ID: <....> (GSuite)
        #
        #   The following fields are not used in Sisimai:
        #     - Original-Envelope-Id
        #     - DSN-Gateway
        {
          'arrival-date'          => ':',
          'received-from-mta'     => ';',
          'reporting-mta'         => ';',
          'x-original-message-id' => '@',
        },

        # https://tools.ietf.org/html/rfc3464#section-2.3
        #   A DSN contains information about attempts to deliver a message to one or more recipi-
        #   ents. The delivery information for any particular recipient is contained in a group of
        #   contiguous per-recipient fields. Each group of per-recipient fields is preceded by a
        #   blank line.
        #
        #   The following fields (not defined in RFC 3464) are used in Sisimai
        #     - X-Actual-Recipient: RFC822; ....
        #
        #   The following fields are not used in Sisimai:
        #     - Will-Retry-Until
        #     - Final-Log-ID
        {
          'action'                => 'e',
          'diagnostic-code'       => ';',
          'final-recipient'       => ';',
          'last-attempt-date'     => ':',
          'original-recipient'    => ';',
          'remote-mta'            => ';',
          'status'                => '.',
          'x-actual-recipient'    => ';',
        }
      ].freeze

      CapturesOn = {
        "addr" => ["Final-Recipient", "Original-Recipient", "X-Actual-Recipient"],
        "code" => ["Diagnostic-Code"],
        "date" => ["Arrival-Date", "Last-Attempt-Date"],
        "host" => ["Received-From-MTA", "Remote-MTA", "Reporting-MTA"],
        "list" => ["Action"],
        "stat" => ["Status"],
       #"text" => ["X-Original-Message-ID", "Final-Log-ID", "Original-Envelope-ID"],
      }.freeze

      SubtypeSet = {"addr" => "RFC822", "cdoe" => "SMTP", "host" => "DNS"}.freeze
      ActionList = ["failed", "delayed", "delivered", "relayed", "expanded"].freeze
      Correction = {'deliverable' => 'delivered', 'expired' => 'failed', 'failure' => 'failed'}
      FieldGroup = {
        'original-recipient'    => 'addr',
        'final-recipient'       => 'addr',
        'x-actual-recipient'    => 'addr',
        'diagnostic-code'       => 'code',
        'arrival-date'          => 'date',
        'last-attempt-date'     => 'date',
        'received-from-mta'     => 'host',
        'remote-mta'            => 'host',
        'reporting-mta'         => 'host',
        'action'                => 'list',
        'status'                => 'stat',
        'x-original-message-id' => 'text',
      }.freeze

      def FIELDINDEX
        return %w[
            Action Arrival-Date Diagnostic-Code Final-Recipient Last-Attempt-Date Original-Recipient
            Received-From-MTA Remote-MTA Reporting-MTA Status X-Actual-Recipient X-Original-Message-ID
        ]
      end

      # Table to be converted to key name defined in Sisimai::Lhost class
      # @param    [Symbol] group  RFC822 Header group name
      # @return   [Array,Hash]    RFC822 Header list
      def FIELDTABLE
        return {
          'action'             => 'action',
          'arrival-date'       => 'date',
          'diagnostic-code'    => 'diagnosis',
          'final-recipient'    => 'recipient',
          'last-attempt-date'  => 'date',
          'original-recipient' => 'alias',
          'received-from-mta'  => 'lhost',
          'remote-mta'         => 'rhost',
          'reporting-mta'      => 'lhost',
          'status'             => 'status',
          'x-actual-recipient' => 'alias',
        }
      end

      # Check the argument matches with a field defined in RFC3464
      # @param    [String] argv0 A line including field and value defined in RFC3464
      # @return   [Integer]      0: did not matched
      #                          1: Matched with per-message field
      #                          2: Matched with per-recipient field
      # @since v4.25.0
      def match(argv0 = '')
        return 0 if argv0.to_s == ""
        label = Sisimai::RFC1894.label(argv0); return 0 if label.empty?
        match = 0

        FieldNames[0].each_key do |e|
          # Per-Message fields
          next if label != e
          next if argv0.include?(FieldNames[0][label]) == false
          match = 1; break
        end
        return match if match > 0

        FieldNames[1].each_key do |e|
          # Per-Recipient field
          next if label != e
          next if argv0.include?(FieldNames[1][label]) == false
          match = 2; break
        end
        return match
      end

      # Returns a field name as a label from the given string
      # @param    [String] argv0 A line including field and value defined in RFC3464
      # @return   [String]       Field name as a label
      # @since v4.25.15
      def label(argv0 = '')
        return "" if argv0.empty?
        return argv0.split(':', 2).shift.downcase
      end

      # Check the argument is including field defined in RFC3464 and return values
      # @param    [String] argv0 A line including field and value defined in RFC3464
      # @return   [Array]        ['field-name', 'value-type', 'Value', 'field-group']
      # @since v4.25.0
      def field(argv0 = '')
        return nil if argv0.empty?
        label = Sisimai::RFC1894.label(argv0)
        group = FieldGroup[label] || ''
        parts = argv0.split(":", 2); parts[1] = parts[1].nil? ? "" : parts[1].split.join(" ")
        return nil if group.empty? || CapturesOn[group].nil?

        # Try to match with each pattern of Per-Message field, Per-Recipient field
        #   - 0: Field-Name
        #   - 1: Sub Type: RFC822, DNS, X-Unix, and so on)
        #   - 2: Value
        #   - 3: Field Group(addr, code, date, host, stat, text)
        #   - 4: Comment
        table = [label, "", "", group, ""]

        case group
        when "addr", "code", "host"
          # - Final-Recipient: RFC822; kijitora@nyaan.jp
          # - Diagnostic-Code: SMTP; 550 5.1.1 <kijitora@example.jp>... User Unknown
          # - Remote-MTA: DNS; mx.example.jp
          if parts[1].include?(";")
            # There is a valid sub type (including ";")
            v = parts[1].split(";", 2)
            table[1] = v[0].split.join(" ").upcase if v.size > 0
            table[2] = v[1].split.join(" ")        if v.size > 1
          else
            # There is no sub type like "Diagnostic-Code: 550 5.1.1 <kijitora@example.jp>..."
            table[2] = parts[1]
            table[1] = SubtypeSet[group] || ""
          end
          table[2] = table[2].downcase if group == "host"
          table[2] = "" if table[2] =~ /\A\s+\z/

        when "list"
          # Action: failed
          # Check that the value is an available value defined in "ActionList" or not.
          # When the value is invalid, convert to an available value defined in "Correction"
          v = parts[1].downcase
          table[2] = v if ActionList.any? { |a| v == a }
          table[2] = Correction[v] if table[2].empty?

        else
          # Other groups such as Status:, Arrival-Date:, or X-Original-Message-ID:.
          # There is no ";" character in the field.
          # - Status: 5.2.2
          # - Arrival-Date: Mon, 21 May 2018 16:09:59 +0900
          table[2] = group == "date" ? parts[1] : parts[1].downcase
        end

        if Sisimai::String.aligned(table[2], [" (", ")"])
          # Extract text enclosed in parentheses as comments
          # Reporting-MTA: dns; mr21p30im-asmtp004.me.example.com (tcp-daemon)
          p1 = table[2].index(" (")
          p2 = table[2].index(")")
          table[4] = table[2][p1 + 2, p2 - p1 - 2]
          table[2] = table[2][0, p1]
        end

        return table
      end

    end
  end
end

