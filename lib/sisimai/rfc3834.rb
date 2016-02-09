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
        :'subject' => %r/\A(?:
             Auto:
            |Out[ ]of[ ]Office:
          )
        /xi,
      }
      Re1 = { :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/ }
      Re2 = {
        :subject => %r/(?:
             SECURITY[ ]information[ ]for  # sudo
            |Mail[ ]failure[ ][-]          # Exim
            )
        /x,
        :from    => %r/(?:root|postmaster|mailer-daemon)[@]/i,
        :to      => %r/root[@]/,
      }

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
      # @return        [Hash, Undef]      Bounce data list and message/rfc822 part
      #                                   or Undef if it failed to parse or the
      #                                   arguments are missing
      def scan(mhead, mbody)
        return nil unless mhead
        return nil unless mbody
        return nil if mhead.keys.size == 0
        return nil if mbody.size == 0

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

        require 'sisimai/mta'
        require 'sisimai/address'
        require 'sisimai/rfc5322'

        dscontents = []; dscontents << Sisimai::MTA.DELIVERYSTATUS
        hasdivided = mbody.split("\n")
        recipients = 0  # (Integer) The number of 'Final-Recipient' header
        maxmsgline = 5  # (Integer) Max message length(lines)
        haveloaded = 0  # (Integer) The number of lines loaded from message body
        blanklines = 0  # (Integer) Counter for countinuous blank lines
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

        # BODY_PARSER: Get vacation message
        hasdivided.each do |e|
          # Read the first 5 lines except a blank line
          unless e.size > 0
            # Check a blank line
            blanklines += 1
            break if blanklines > 1
            next
          end
          next unless e =~ / /

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

        if mhead['received'].size > 0
          # Get localhost and remote host name from Received header.
          r = mhead['received']
          %w|'lhost', 'rhost'|.each { |a| v[a] ||= '' }
          v['lhost'] = Sisimai::RFC5322.received(r[0]).shift if v['lhost'].empty?
          v['rhost'] = Sisimai::RFC5322.received(r[-1]).pop  if v['rhost'].empty?
        end

        v.each_key { |a| v[a] ||= '' }
        return { 'ds' => dscontents, 'rfc822' => '' }
      end

    end
  end
end
