module Sisimai
  module SMTP
    # Sisimai::SMTP::Failure is utilities for checking SMTP Errors from error message text.
    module Failure
      class << self
        require 'sisimai/smtp/reply'
        require 'sisimai/smtp/status'

        # Returns true if the given string indicates a permanent error
        # @param    [String] argv1  String including SMTP Status code
        # @return   [Boolean]       true:  Permanet error
        #                           false: Is not a permanent error
        # @since v4.17.3
        def is_permanent(argv1 = '')
          return false unless argv1
          return false unless argv1.size > 0

          statuscode = Sisimai::SMTP::Status.find(argv1) || Sisimai::SMTP::Reply.find(argv1) || ''
          return true if statuscode[0, 1] == "5"
          return true if argv1.downcase.include?(' permanent ')
          return false
        end

        # Returns true if the given string indicates a temporary error
        # @param    [String] argv1  String including SMTP Status code
        # @return   [Boolean]       true:  Temporary error
        #                           false: is not a temporary error
        # @since v5.2.0
        def is_temporary(argv1 = '')
          return false unless argv1
          return false unless argv1.size > 0

          statuscode = Sisimai::SMTP::Status.find(argv1) || Sisimai::SMTP::Reply.find(argv1) || ''
          issuedcode = argv1.downcase

          return true if statuscode[0, 1] == "4"
          return true if issuedcode.include?(' temporar')
          return true if issuedcode.include?(' persistent')
          return false
        end

        # Checks the reason sisimai detected is a hard bounce or not
        # @param    [String] argv1  Detected bounce reason
        # @param    [String] argv2  String including SMTP Status code
        # @return   [Boolean]       true: is a hard bounce
        def is_hardbounce(argv1 = '', argv2 = '')
          return false unless argv1
          return false unless argv1.size > 0

          return false if argv1 == "undefined" || argv1 == "onhold"
          return false if argv1 == "delivered" || argv1 == "feedback"    || argv1 == "vacation"
          return true  if argv1 == "hasmoved"  || argv1 == "userunknown" || argv1 == "hostunknown"
          return false if argv1 != "notaccept" 

          # NotAccept: 5xx => hard bounce, 4xx => soft bounce
          hardbounce = false
          if argv2.size > 0
            # Check the 2nd argument(a status code or a reply code)
            cv = Sisimai::SMTP::Status.find(argv2, "") || Sisimai::SMTP::Reply.find(argv2, "") || ""

            # The SMTP status code or the SMTP reply code starts with "5"
            # Deal as a hard bounce when the error message does not indicate a temporary error 
            hardbounce = true if cv[0, 1] == "5" || Sisimai::SMTP::Failure.is_temporary(argv2) == false
          else
            # Deal "NotAccept" as a hard bounce when the 2nd argument is empty
            hardbounce = true
          end
          return hardbounce
        end

        # Checks the reason sisimai detected is a soft bounce or not
        # @param    [String] argv1  Detected bounce reason
        # @param    [String] argv2  String including SMTP Status code
        # @return   [Boolean]       true: is a soft bounce
        def is_softbounce(argv1 = '', argv2 = '')
          return false unless argv1
          return false unless argv1.size > 0

          return false if argv1 == "delivered" || argv1 == "feedback"    || argv1 == "vacation"
          return false if argv1 == "hasmoved"  || argv1 == "userunknown" || argv1 == "hostunknown"
          return true  if argv1 == "undefined" || argv1 == "onhold"
          return true  if argv1 != "notaccept" 

          # NotAccept: 5xx => hard bounce, 4xx => soft bounce
          softbounce = false
          if argv2.size > 0
            # Check the 2nd argument(a status code or a reply code)
            cv = Sisimai::SMTP::Status.find(argv2, "") || Sisimai::SMTP::Reply.find(argv2, "") || ""

            # The SMTP status code or the SMTP reply code starts with "4"
            softbounce = true if cv[0, 1] == "4"
          end
          return softbounce
        end

      end
    end
  end
end
