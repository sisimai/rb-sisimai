module Sisimai
  # Sisimai::RFC3834 - RFC3834 auto reply message detector
  module RFC3834
    # Imported from p5-Sisimail/lib/Sisimai/RFC3834.pm
    class << self
      # http://tools.ietf.org/html/rfc3834
      Re0 = {
        # http://www.iana.org/assignments/auto-submitted-keywords/auto-submitted-keywords.xhtml
        :'auto-submitted' => %r/\Aauto-(?:generated|replied|notified)/i,
        # https://msdn.microsoft.com/en-us/library/ee219609(v=exchg.80).aspx
        :'x-auto-response-suppress' => %r/(?:OOF|AutoReply)/i,
        :'precedence' => %r/\Aauto_reply\z/,
        :'subject' => %r/\A(?>
             Auto:
            |Auto[ ]Response:
            |Automatic[ ]reply:
            |Out[ ]of[ ](?:the[ ])*Office:
          )
        /xi,
      }.freeze
      Re1 = {
        :boundary => %r/\A__SISIMAI_PSEUDO_BOUNDARY__\z/,
        :endof    => %r/\A__END_OF_EMAIL_MESSAGE__\z/
      }.freeze
      Re2 = {
        :subject => %r/(?:
             SECURITY[ ]information[ ]for  # sudo
            |Mail[ ]failure[ ][-]          # Exim
            )
        /x,
        :from    => %r/(?:root|postmaster|mailer-daemon)[@]/i,
        :to      => %r/root[@]/,
      }.freeze
      ReV = %r{\A(?>
         (?:.+?)?Re:
        |Auto(?:[ ]Response):
        |Automatic[ ]reply:
        |Out[ ]of[ ]Office:
        )
        [ ]*(.+)\z
      }xi

      def description; 'Detector for auto replied message'; end
      def smtpagent;   'RFC3834'; end
      def pattern;     return Re0; end
      def headerlist
        return [
          'Auto-Submitted',
          'Precedence',
          'X-Auto-Response-Suppress',
        ]
      end

      # Detect auto reply message as RFC3834
      # @param         [Hash] mhead       Message header of a bounce email
      # @options mhead [String] from      From header
      # @options mhead [String] date      Date header
      # @options mhead [String] subject   Subject header
      # @options mhead [Array]  received  Received headers
      # @options mhead [String] others    Other required headers
      # @param         [String] mbody     Message body of a bounce email
      # @return        [Hash, Nil]        Bounce data list and message/rfc822 part
      #                                   or nil if it failed to parse or the
      #                                   arguments are missing
      def scan(mhead, mbody)
        return nil unless mhead
        return nil unless mbody
        return nil if mhead.keys.size.zero?
        return nil if mbody.size.zero?

        leave = 0
        match = 0

        # DETECT_EXCLUSION_MESSAGE
        Re2.each_key do |e|
          # Exclude message from root@
          next unless mhead.key?(e.to_s)
          next unless mhead[e.to_s]
          next unless mhead[e.to_s] =~ Re2[e]
          leave = 1
          break
        end
        return nil if leave > 0

        # DETECT_AUTO_REPLY_MESSAGE
        Re0.each_key do |e|
          # RFC3834 Auto-Submitted and other headers
          next unless mhead.key?(e.to_s)
          next unless mhead[e.to_s]
          next unless mhead[e.to_s] =~ Re0[e]
          match += 1
          break
        end
        return nil if match < 1

        require 'sisimai/bite/email'
        require 'sisimai/address'

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822part = '' # (String) message/rfc822-headers part
        recipients = 0  # (Integer) The number of 'Final-Recipient' header
        maxmsgline = 5  # (Integer) Max message length(lines)
        haveloaded = 0  # (Integer) The number of lines loaded from message body
        blanklines = 0  # (Integer) Counter for countinuous blank lines
        countuntil = 1  # (Integer) Maximum value of blank lines in the body part
        v = dscontents[-1]

        # RECIPIENT_ADDRESS
        ['from', 'return-path'].each do |e|
          # Try to get the address of the recipient
          next unless mhead.key?(e)
          next unless mhead[e]
          v['recipient'] = mhead[e]
          break
        end

        if v['recipient']
          # Clean-up the recipient address
          v['recipient'] = Sisimai::Address.s3s4(v['recipient'])
          recipients += 1
        end
        return nil unless recipients > 0

        if mhead['content-type']
          # Get the boundary string and set regular expression for matching with
          # the boundary string.
          require 'sisimai/mime'
          b0 = Sisimai::MIME.boundary(mhead['content-type'], 0)
          Re1[:boundary] = %r/\A\Q#{b0}\E\z/ unless b0.empty?
        end

        # BODY_PARSER: Get vacation message
        hasdivided.each do |e|
          # Read the first 5 lines except a blank line
          countuntil += 1 if e =~ Re1[:boundary]

          unless e.size > 0
            # Check a blank line
            blanklines += 1
            break if blanklines > countuntil
            next
          end
          next unless e =~ / /
          next if e =~ /\AContent-(?:Type|Transfer)/

          v['diagnosis'] ||= ''
          v['diagnosis']  += e + ' '
          haveloaded += 1
          break if haveloaded >= maxmsgline
        end
        v['diagnosis'] ||= mhead['subject']

        require 'sisimai/string'
        v['diagnosis'] = Sisimai::String.sweep(v['diagnosis'])
        v['reason']    = 'vacation'
        v['agent']     = self.smtpagent
        v['date']      = mhead['date']
        v['status']    = ''

        v.each_key { |a| v[a] ||= '' }

        if cv = mhead['subject'].match(ReV)
          # Get the Subject header from the original message
          rfc822part = sprintf("Subject: %s\n", cv[1])
        end
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end
