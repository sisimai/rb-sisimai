module Sisimai
  # Sisimai::RFC3834 - RFC3834 auto reply message detector
  module RFC3834
    class << self
      # http://tools.ietf.org/html/rfc3834
      MarkingsOf = { :boundary => '__SISIMAI_PSEUDO_BOUNDARY__' }
      LowerLabel = %w[from to subject auto-submitted precedence x-apple-action x-auto-response-suppress].freeze
      DoNotParse = {
        'from'    => ['root@', 'postmaster@', 'mailer-daemon@'],
        'to'      => ['root@'],
        'subject' => [
            'security information for', # sudo(1)
            'mail failure -',           # Exim
        ],
      }.freeze
      AutoReply0 = {
        # http://www.iana.org/assignments/auto-submitted-keywords/auto-submitted-keywords.xhtml
        'auto-submitted' => ['auto-generated', 'auto-replied', 'auto-notified'],
        'precedence'     => ['auto_reply'],
        'subject'        => ['auto:', 'auto response:', 'automatic reply:', 'out of office:', 'out of the office:'],
        'x-apple-action' => ['vacation'],
      }.freeze
      AutoReply1 = { 'x-auto-response-suppress' => ['oof', 'autoreply'] }.freeze
      SubjectSet = %r{\A(?>
         (?:.+?)?re:
        |auto(?:[ ]response):
        |automatic[ ]reply:
        |out[ ]of[ ]office:
        )
        [ ]*(.+)\z
      }x.freeze

      # Detect auto reply message as RFC3834
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to parse or the arguments are missing
      def inquire(mhead, mbody)
        leave = 0
        match = 0
        lower = {} 

        LowerLabel.each do |e|
          # Set lower-cased value of each header related to auto-response
          next unless mhead.has_key?(e)
          lower[e] = mhead[e].downcase
        end

        # DETECT_EXCLUSION_MESSAGE
        DoNotParse.each_key do |e|
          # Exclude message from root@
          next unless lower[e]
          next unless DoNotParse[e].any? { |a| lower[e].include?(a) }
          leave = 1
          break
        end
        return nil if leave > 0

        # DETECT_AUTO_REPLY_MESSAGE0
        AutoReply0.each_key do |e|
          # RFC3834 Auto-Submitted and other headers
          next unless lower[e]
          next unless AutoReply0[e].any? { |a| lower[e].include?(a) }
          match += 1
          break
        end

        # DETECT_AUTO_REPLY_MESSAGE0
        AutoReply1.each_key do |e|
          # X-Auto-Response-Suppress: header and other headers
          break if match > 0
          next unless lower[e]
          next unless AutoReply1[e].any? { |a| lower[e].include?(a) }
          match += 1
          break
        end
        return nil if match < 1

        require 'sisimai/lhost'
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        bodyslices = mbody.scrub('?').split("\n")
        rfc822part = '' # (String) message/rfc822-headers part
        recipients = 0  # (Integer) The number of 'Final-Recipient' header
        maxmsgline = 5  # (Integer) Max message length(lines)
        haveloaded = 0  # (Integer) The number of lines loaded from message body
        blanklines = 0  # (Integer) Counter for countinuous blank lines
        countuntil = 1  # (Integer) Maximum value of blank lines in the body part
        v = dscontents[-1]

        # RECIPIENT_ADDRESS
        %w[from return-path].each do |e|
          # Try to get the address of the recipient
          next unless mhead[e]
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
          # Get the boundary string and set regular expression for matching with the boundary string.
          q = Sisimai::RFC2045.boundary(mhead['content-type'], 0) || ''
          MarkingsOf[:boundary] = q unless q.empty?
        end

        # BODY_PARSER: Get vacation message
        while e = bodyslices.shift do
          # Read the first 5 lines except a blank line
          countuntil += 1 if e.include?(MarkingsOf[:boundary])

          if e.empty?
            # Check a blank line
            blanklines += 1
            break if blanklines > countuntil
            next
          end
          next unless e.include?(' ')
          next if     e.start_with?('Content-Type')
          next if     e.start_with?('Content-Transfer')

          v['diagnosis'] ||= ''
          v['diagnosis']  << e + ' '
          haveloaded += 1
          break if haveloaded >= maxmsgline
        end
        v['diagnosis'] ||= mhead['subject']
        v['diagnosis'] = Sisimai::String.sweep(v['diagnosis'])
        v['reason']    = 'vacation'
        v['date']      = mhead['date']
        v['status']    = ''

        if cv = lower['subject'].match(SubjectSet)
          # Get the Subject header from the original message
          rfc822part = 'Subject: ' << cv[1] + "\n"
        end
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end
      def description; 'Detector for auto replied message'; end
    end
  end
end
