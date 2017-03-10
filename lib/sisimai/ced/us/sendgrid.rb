module Sisimai
  module CED::US
    # Sisimai::CED::US::SendGrid parses a bounce object(JSON) which created by
    # SendGrid.  # Methods in the module are called from only Sisimai::Message.
    module SendGrid
      # Imported from p5-Sisimail/lib/Sisimai/CED/US/SendGrid.pm
      class << self
        require 'sisimai/ced'
        require 'sisimai/rfc5322'

        def headerlist;  return []; end
        def pattern;     return {}; end
        def smtpagent;   return Sisimai::CED.smtpagent(self); end
        def description; return 'SendGrid(JSON): http://sendgrid.com/'; end

        # @abstract Adapt SendGrid bounce object for Sisimai::Message format
        # @param        [Hash] argvs  bounce object(JSON) retrieved from SendGrid API
        # @return       [Hash, Nil]   Bounce data list and message/rfc822 part
        #                             or Undef if it failed to parse or the
        #                             arguments are missing
        # @since v4.20.0
        def adapt(argvs)
          return nil unless argvs.is_a? Hash
          return nil unless argvs.keys.size > 0
          return nil unless argvs.key?('email')

          dscontents = [Sisimai::CED.DELIVERYSTATUS]
          rfc822head = {}     # (Hash) Check flags for headers in RFC822 part
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          v = dscontents[-1]

          require 'sisimai/string'
          require 'sisimai/address'
          require 'sisimai/rfc5322'

          if Sisimai::RFC5322.is_emailaddress(argvs['email'])
            #   {
            #       "status": "4.0.0",
            #       "created": "2011-09-16 22:02:19",
            #       "reason": "Unable to resolve MX host sendgrid.ne",
            #       "email": "esting@sendgrid.ne"
            #   },
            recipients += 1
            v['recipient'] = argvs['email']
            v['date'] = argvs['created'] || ''

            statuscode = argvs['status']  || ''
            diagnostic = Sisimai::String.sweep(argvs['reason']) || ''

            if statuscode =~ /\A[245]\d\d\z/
              # "status": "550"
              v['replycode'] = statuscode

            elsif statuscode =~ /\A[245][.]\d[.]\d+\z/
              # "status": "5.1.1"
              v['status'] = statuscode
            end

            require 'sisimai/smtp/reply'
            require 'sisimai/smtp/status'
            v['status']    ||= Sisimai::SMTP::Status.find(diagnostic)
            v['replycode'] ||= Sisimai::SMTP::Reply.find(diagnostic)
            v['diagnosis']   = argvs['reason'] || ''
            v['agent']       = Sisimai::CED::US::SendGrid.smtpagent

            # Generate pseudo message/rfc822 part
            rfc822head = {
              'to'   => argvs['email'],
              'from' => Sisimai::Address.undisclosed('s'),
              'date' => v['date'],
            }
          else
            # The value of $argvs->{'email'} does not seems to an email address
            return nil
          end

          return nil if recipients.zero?
          return { 'ds' => dscontents, 'rfc822' => rfc822head }
        end

      end
    end
  end
end


