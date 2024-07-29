module Sisimai
  # Sisimai::RFC1894 DSN field defined in RFC3464 (obsoletes RFC1894)
  module RFC1894
    class << self
      FieldNames = {
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
        'arrival-date'          => ':',
        'received-from-mta'     => ';',
        'reporting-mta'         => ';',
        'x-original-message-id' => '@',

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
        'action'                => 'e',
        'diagnostic-code'       => ';',
        'final-recipient'       => ';',
        'last-attempt-date'     => ':',
        'original-recipient'    => ';',
        'remote-mta'            => ';',
        'status'                => '.',
        'x-actual-recipient'    => ';',
      }.freeze

      CapturesOn = {
        'addr' => %r/\A((?:Original|Final|X-Actual)-Recipient):[ ](.+?);[ ]*(.+)/,
        'code' => %r/\A(Diagnostic-Code):[ ](.+?);[ ]*(.*)/,
        'date' => %r/\A((?:Arrival|Last-Attempt)-Date):[ ](.+)/,
        'host' => %r/\A((?:Received-From|Remote|Reporting)-MTA):[ ](.+?);[ ]*(.+)/,
        'list' => %r/\A(Action):[ ](delayed|deliverable|delivered|expanded|expired|failed|failure|relayed)/i,
        'stat' => %r/\A(Status):[ ]([245][.]\d+[.]\d+)/,
        'text' => %r/\A(X-Original-Message-ID):[ ](.+)/,
       #'text' => %r/\A(Final-Log-ID|Original-Envelope-Id):[ ]*(.+)/,
      }.freeze

      Correction = { action: { 'deliverable' => 'delivered', 'expired' => 'delayed', 'failure' => 'failed' }}
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
          'reporting-mta'      => 'rhost',
          'status'             => 'status',
          'x-actual-recipient' => 'alias',
        }
      end

      # Check the argument matches with a field defined in RFC3464
      # @param    [String] argv0 A line including field and value defined in RFC3464
      # @return   [Boolean]      false: did not matched, true: matched
      # @since v4.25.0
      def match(argv0 = '')
        label = Sisimai::RFC1894.label(argv0)

        return false unless label
        return false unless FieldNames.has_key?(label)
        return false unless argv0.include?(FieldNames[label])
        return true
      end

      # Returns a field name as a lqbel from the given string
      # @param    [String] argv0 A line including field and value defined in RFC3464
      # @return   [String]       Field name as a label
      # @since v4.25.15
      def label(argv0 = '')
        return nil if argv0.empty?
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

        return nil if group.empty?
        return nil unless CapturesOn[group]

        table = ['', '', '', '']
        match = false
        while cv = argv0.match(CapturesOn[group])
          # Try to match with each pattern of Per-Message field, Per-Recipient field
          #   - 0: Field-Name
          #   - 1: Sub Type: RFC822, DNS, X-Unix, and so on)
          #   - 2: Value
          #   - 3: Field Group(addr, code, date, host, stat, text)
          match = true
          table[0] = cv[1].downcase
          table[3] = group

          if group == 'addr' || group == 'code' || group == 'host'
            # - Final-Recipient: RFC822; kijitora@nyaan.jp
            # - Diagnostic-Code: SMTP; 550 5.1.1 <kijitora@example.jp>... User Unknown
            # - Remote-MTA: DNS; mx.example.jp
            table[1] = cv[2].upcase
            table[2] = group == 'host' ? cv[3].downcase : cv[3]
            table[2] = '' if table[2] =~ /\A\s+\z/  # Remote-MTA: dns;
          else
            # - Action: failed
            # - Status: 5.2.2
            table[1] = ''
            table[2] = group == 'date' ? cv[2] : cv[2].downcase

            # Correct invalid value in Action field:
            break unless group == 'list'
            break unless Correction[:action][table[2]]
            table[2] = Correction[:action][table[2]]
          end
          break
        end
        return nil unless match
        return table
      end

    end
  end
end

