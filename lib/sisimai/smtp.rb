module Sisimai
  # Sisimai::SMTP is a parent class of Sisimai::SMTP::Status and Sisimai::SMTP::Reply.
  module SMTP
    class << self
      # Check softbounce or not
      # @param    [String] argv1    String including SMTP Status code
      # @return   [True,False,Nil]  true:  Soft bounce
      #                             false: Hard bounce
      #                             nil: May not be bounce ?
      def is_softbounce(argv1 = '')
        return nil unless argv1
        return nil unless argv1.size > 0

        mesgstring = argv1.to_s
        classvalue = nil
        softbounce = -1

        if cv = mesgstring.match(/\b([245])\d\d\b/)
          # Valid SMTP reply code such as 550, 421
          classvalue = cv[1].to_i

        elsif cv = mesgstring.match(/\b([245])[.][0-9][.]\d+\b/)
          # DSN value such as 5.1.1, 4.4.7
          classvalue = cv[1].to_i
        end

        if classvalue == 4
          # Soft bounce, Persistent transient error
          softbounce = true

        elsif classvalue == 5
          # Hard bounce, Permanent error
          softbounce = false
        else
          # Check with regular expression
          if mesgstring =~ /(?:temporar|persistent)/i
            # Temporary failure
            softbounce = true

          elsif mesgstring =~ /permanent/i
            # Permanently failure
            softbounce = false

          else
            # did not find information to decide that it is a soft bounce
            # or a hard bounce.
            softbounce = nil
          end
        end

        return softbounce
      end
    end
  end
end

