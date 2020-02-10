module Sisimai::Lhost
  # Sisimai::Lhost::UserDefined is an example module as a template to
  # implement your custom MTA module.
  module UserDefined
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Lhost/UserDefined.pm
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      ReBackbone = %r<^Content-Type:[ ](?:message/rfc822|text/rfc822-headers)>.freeze
      MarkingsOf = {
        # MarkingsOf is a delimiter set of these sections:
        #   message: The first line of a bounce message to be parsed.
        #   error:   The first line of an error message to get an error reason, recipient
        #            addresses, or other bounce information.
        #   rfc822:  The first line of the original message.
        message: %r/\A[ \t]+[-]+ Transcript of session follows [-]+\z/,
        error:   %r/\A[.]+ while talking to .+[:]\z/,
      }.freeze

      def description; return 'Module description'; end
      def smtpagent;   return Sisimai::Lhost.smtpagent(self); end

      # @abstract Template for User-Defined MTA module
      # @param         [Hash] mhead       Message headers of a bounce email
      # @options mhead [String] from      From header
      # @options mhead [String] date      Date header
      # @options mhead [String] subject   Subject header
      # @options mhead [Array]  received  Received headers
      # @options mhead [String] others    Other required headers
      # @param         [String] mbody     Message body of a bounce email
      # @return        [Hash, Nil]        Bounce data list and message/rfc822
      #                                   part or nil if it failed to parse or
      #                                   the arguments are missing
      def make(mhead, mbody)
        # 1. Check some value in mhead using regular expression or "==" operator
        #    whether the bounce message should be parsed by this module or not.
        #   - Matched 1 or more values: Proceed to the step 2.
        #   - Did not matched:          return nil
        #
        match  = 0
        match += 1 if mhead['subject'].start_with?('Error Mail Report')
        match += 1 if mhead['from'].include?('Mail System')
        match += 1 if mhead['x-some-userdefined-header']
        return nil unless match > 0

        # 2. Parse message body(mbody) of the bounce message. See some modules
        #    in lib/sisimai/lhost directory to implement codes.
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        emailsteak = Sisimai::RFC5322.fillet(mbody, ReBackbone)
        bodyslices = emailsteak[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email
          # to the previous line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            readcursor |= Indicators[:deliverystatus] if e =~ MarkingsOf[:message]
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0
          next if e.empty?

          # Code for getting a recipient address and other values you require
        end

        # The following code is dummy to be passed "make test".
        dscontents[0]['recipient'] = 'kijitora@example.jp'
        dscontents[0]['diagnosis'] = '550 something wrong'
        dscontents[0]['status']    = '5.1.1'
        dscontents[0]['spec']      = 'SMTP'
        dscontents[0]['date']      = 'Thu 29 Apr 2010 23:34:45 +0900'
        dscontents[0]['agent']     = self.smtpagent
        recipients = 1 if dscontents[0]['recipient']

        emailsteak[1] << 'From: shironeko@example.org' << "\n"
        emailsteak[1] << 'Subject: Nyaaan' << "\n"
        emailsteak[1] << 'Message-Id: 000000000000@example.jp' << "\n"

        # 3. Return nil when there is no recipient address which is failed to
        #    delivery in the bounce message
        return nil unless recipients > 0

        # 4. Return the following variable.
        return { 'ds' => dscontents, 'rfc822' => emailsteak[1] }
      end

    end
  end
end

