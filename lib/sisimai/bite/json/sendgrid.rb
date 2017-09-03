module Sisimai::Bite::JSON
  # Sisimai::Bite::JSON::SendGrid parses a bounce object(JSON) which created by
  # SendGrid. Methods in the module are called from only Sisimai::Message.
  module SendGrid
    # Imported from p5-Sisimail/lib/Sisimai/Bite/JSON/SendGrid.pm
    class << self
      require 'sisimai/bite/json'

      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def description; return 'SendGrid(JSON): http://sendgrid.com/'; end

      # @abstract Adapt SendGrid bounce object for Sisimai::Message format
      # @param        [Hash] argvs  bounce object(JSON) retrieved from SendGrid API
      # @return       [Hash, Nil]   Bounce data list and message/rfc822 part or
      #                             nil if it failed to parse or the
      #                             arguments are missing
      # @since v4.20.0
      def adapt(argvs)
        return nil unless argvs.is_a? Hash
        return nil unless argvs.keys.size > 0
        return nil unless argvs.key?('email')
        return nil unless Sisimai::RFC5322.is_emailaddress(argvs['email'])

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        v = dscontents[-1]

        require 'sisimai/string'
        require 'sisimai/address'

        #   {
        #       "status": "4.0.0",
        #       "created": "2011-09-16 22:02:19",
        #       "reason": "Unable to resolve MX host sendgrid.ne",
        #       "email": "esting@sendgrid.ne"
        #   },
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
        v['agent']       = self.smtpagent

        # Generate pseudo message/rfc822 part
        rfc822head = {
          'to'   => argvs['email'],
          'from' => Sisimai::Address.undisclosed('s'),
          'date' => v['date'],
        }
        return { 'ds' => dscontents, 'rfc822' => rfc822head }
      end

    end
  end
end

