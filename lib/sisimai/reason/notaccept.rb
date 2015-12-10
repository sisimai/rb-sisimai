module Sisimai
  module Reason
    module NotAccept
      # Imported from p5-Sisimail/lib/Sisimai/Reason/NotAccept.pm
      class << self
        def text; return 'notaccept'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1

          # Destination mail server does not accept any message
          regex = %r/smtp[ ]protocol[ ]returned[ ]a[ ]permanent[ ]error/xi

          return true if argv1 =~ regex
          return false
        end

        # Remote host does not accept any message
        # @param    [Sisimai::Data] argvs   Object to be detected the reason
        # @return   [True,False]            true: Not accept
        #                                   false: Accept
        # @see http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return true if argvs.reason == self.text

          diagnostic = argvs.diagnosticcode || ''
          v = false

          if argvs.replycode =~ /\A(?:521|554|556)\z/
            # SMTP Reply Code is 554 or 556
            v = false
          else
            # Check the value of Diagnosic-Code: header with patterns
            if argvs.smtpcommand == 'MAIL'
              # Matched with a pattern in this class
              v = true if self.match(diagnostic)
            end
          end
          return v
        end

      end
    end
  end
end



