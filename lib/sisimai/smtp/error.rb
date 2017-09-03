module Sisimai
  module SMTP
    # Sisimai::SMTP::Error is utilities for checking SMTP Errors from error
    # message text.
    module Error
      # Imported from p5-Sisimail/lib/Sisimai/SMTP/Error.pm
      class << self
        require 'sisimai/smtp/reply'
        require 'sisimai/smtp/status'

        SoftOrHard = {
          :soft => %w|
            blocked contenterror exceedlimit expired filtered mailboxfull
            mailererror mesgtoobig networkerror norelaying policyviolation
            rejected securityerror spamdetected suspend syntaxerror systemerror
            systemfull toomanyconn virusdetected
          |,
          :hard => %w|hasmoved hostunknown userunknown|
        }.freeze

        # Permanent error or not
        # @param    [String] argv1  String including SMTP Status code
        # @return   [Boolean]       true:  Permanet error
        #                           false: Temporary error
        #                           nil:   is not an error
        # @since v4.17.3
        def is_permanent(argv1 = '')
          return nil unless argv1
          return nil unless argv1.size > 0

          getchecked = nil
          statuscode = Sisimai::SMTP::Status.find(argv1)
          statuscode = Sisimai::SMTP::Reply.find(argv1) if statuscode.empty?
          classvalue = statuscode[0, 1].to_i

          if classvalue > 0
            # 2, 4, or 5
            if classvalue == 5
              # Permanent error
              getchecked = true

            elsif classvalue == 4
              # Temporary error
              getchecked = false

            elsif classvalue == 2
              # Succeeded
              getchecked = nil
            end
          else
            # Check with regular expression
            getchecked = if argv1 =~ /(?:temporar|persistent)/i
                           # Temporary failure
                           false
                         elsif argv1 =~ /permanent/i
                           # Permanently failure
                           true
                         end
          end

          return getchecked
        end

        # Check softbounce or not
        # @param    [String] argv1  Detected bounce reason
        # @param    [String] argv2  String including SMTP Status code
        # @return   [String]        'soft': Soft bounce
        #                           'hard': Hard bounce
        #                           '':     May not be bounce ?
        # @since v4.17.3
        def soft_or_hard(argv1 = '', argv2 = '')
          return '' if argv1.empty?

          getchecked = nil
          softorhard = nil

          if argv1 =~ /\A(?:delivered|feedback|vacation)\z/
            # These are not dealt as a bounce reason
            softorhard = ''

          elsif argv1 == 'onhold' || argv1 == 'undefined'
            # Check with the value of D.S.N. in argv2
            getchecked = Sisimai::SMTP::Error.is_permanent(argv2)

            if getchecked.nil?
              softorhard = ''
            else
              softorhard = if getchecked
                             'hard'
                           else
                             'soft'
                           end
            end

          elsif argv1 == 'notaccept'
            # NotAccept: 5xx => hard bounce, 4xx => soft bounce
            if argv2.size > 0
              # Get D.S.N. or SMTP reply code from The 2nd argument string
              statuscode = Sisimai::SMTP::Status.find(argv2)
              statuscode = Sisimai::SMTP::Reply.find(argv2) if statuscode.empty?
              classvalue = statuscode[0, 1].to_i

              softorhard = if classvalue == 4
                             # Deal as a "soft bounce"
                             'soft'
                           else
                             # 5 or 0, deal as a "hard bounce"
                             'hard'
                           end
            else
              # "notaccept" is a hard bounce
              softorhard = 'hard'
            end

          else
            # Check all the reasons defined at the above
            catch :SOFT_OR_HARD do
              loop do
                [:hard, :soft].each do |e|
                  # Soft or Hard?
                  SoftOrHard[e].each do |f|
                    # Hard bounce?
                    next unless argv1 == f
                    softorhard = e.to_s
                    throw :SOFT_OR_HARD
                  end
                end

                break
              end
            end
          end

          return softorhard
        end

      end
    end
  end
end
