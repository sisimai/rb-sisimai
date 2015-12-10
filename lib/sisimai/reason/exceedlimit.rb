module Sisimai
  module Reason
    # Sisimai::Reason::ExceedLimit checks the bounce reason is "exceedlimit" or
    # not. This class is called only Sisimai::Reason class.
    #
    # This is the error that a message was rejected due to an email exceeded the
    # limit. The value of D.S.N. is 5.2.3. This reason is almost the same as
    # "MesgTooBig", we think.
    module ExceedLimit
      # Imported from p5-Sisimail/lib/Sisimai/Reason/ExceedLimit.pm
      class << self
        def text; return 'exceedlimit'; end

        # Try to match that the given text and regular expressions
        # @param    [String] argv1  String to be matched with regular expressions
        # @return   [True,False]    false: Did not match
        #                           true: Matched
        def match(argv1)
          return nil unless argv1
          regex = %r/message too large/

          return true if argv1 =~ regex
          return false
        end

        # Exceed limit or not
        # @param    [Sisimai::Data] argvs Object to be detected the reason
        # @return   [True,False]          true: Exceeds the limit
        #                                 false: Did not exceed the limit
        # @see      http://www.ietf.org/rfc/rfc2822.txt
        def true(argvs)
          return nil unless argvs
          return nil unless argvs.is_a? Sisimai::Data
          return nil unless argvs.deliverystatus.size > 0
          return true if argvs.reason == Sisimai::Reason::ExceedLimit.text

          require 'sisimai/smtp/status'
          statuscode = argvs.deliverystatus || ''
          reasontext = Sisimai::Reason::ExceedLimit.text
          diagnostic = argvs.diagnosticcode || ''
          v = false

          if Sisimai::SMTP::Status.name(statuscode) == reasontext
            # Delivery status code points exceedlimit.
            # Status: 5.2.3
            # Diagnostic-Code: SMTP; 552 5.2.3 Message size exceeds fixed maximum message size
            v = true
          else
            # Check the value of Diagnosic-Code: header with patterns
            v = true if Sisimai::Reason::ExceedLimit.match(diagnostic)
          end

          return v
        end

      end
    end
  end
end

