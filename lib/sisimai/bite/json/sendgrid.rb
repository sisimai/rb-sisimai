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
        return nil if argvs.empty?
        return nil unless argvs.key?('email')
        return nil unless Sisimai::RFC5322.is_emailaddress(argvs['email'])

        dscontents = nil
        rfc822head = {}
        v = nil

        if argvs.key?('event')
          # https://sendgrid.com/docs/API_Reference/Webhooks/event.html
          # {
          #   'tls' => 0,
          #   'timestamp' => 1504555832,
          #   'event' => 'bounce',
          #   'email' => 'mailboxfull@example.jp',
          #   'ip' => '192.0.2.22',
          #   'sg_message_id' => '03_Wof6nRbqqzxRvLpZbfw.filter0017p3mdw1-11399-59ADB335-16.0',
          #   'type' => 'blocked',
          #   'sg_event_id' => 'S4wr46YHS0qr3BKhawTQjQ',
          #   'reason' => '550 5.2.2 <mailboxfull@example.jp>... Mailbox Full ',
          #   'smtp-id' => '<201709042010.v84KAQ5T032530@example.nyaan.jp>',
          #   'status' => '5.2.2'
          # },
          return nil unless %w[bounce deferred delivered spamreport].include?(argvs['event'])
          dscontents = [Sisimai::Bite.DELIVERYSTATUS]
          diagnostic = argvs['reason']   || ''
          diagnostic = argvs['response'] || '' if diagnostic.empty?
          timestamp0 = Sisimai::Time.parse(::Time.at(argvs['timestamp']).to_s)
          v = dscontents[-1]

          v['date']      = timestamp0.strftime("%a, %d %b %Y %T %z")
          v['agent']     = self.smtpagent
          v['lhost']     = argvs['ip'] || ''
          v['status']    = argvs['status'] || nil
          v['diagnosis'] = Sisimai::String.sweep(diagnostic)
          v['recipient'] = argvs['email']

          if argvs['event'] == 'delivered'
            # "event": "delivered"
            v['reason'] = 'delivered'
          elsif argvs['event'] == 'spamreport'
            # [
            #   {
            #     "email": "kijitora@example.com",
            #     "timestamp": 1504837383,
            #     "sg_message_id": "6_hrAeKvTDaB5ynBI2nbnQ.filter0002p3las1-27574-59B1FDA3-19.0",
            #     "sg_event_id": "o70uHqbMSXOaaoveMZIjjg",
            #     "event": "spamreport"
            #   }
            # ]
            v['reason'] = 'feedback'
            v['feedbacktype'] = 'abuse'
          end
          v['status']    ||= Sisimai::SMTP::Status.find(v['diagnosis']) || ''
          v['replycode'] ||= Sisimai::SMTP::Reply.find(v['diagnosis'])  || ''

          # Generate pseudo message/rfc822 part
          rfc822head = {
            'from'       => Sisimai::Address.undisclosed('s'),
            'message-id' => v['sg_message_id'],
          }
        else
          #   {
          #       "status": "4.0.0",
          #       "created": "2011-09-16 22:02:19",
          #       "reason": "Unable to resolve MX host sendgrid.ne",
          #       "email": "esting@sendgrid.ne"
          #   },
          dscontents = [Sisimai::Bite.DELIVERYSTATUS]
          v = dscontents[-1]

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

          v['status']    ||= Sisimai::SMTP::Status.find(diagnostic)
          v['replycode'] ||= Sisimai::SMTP::Reply.find(diagnostic)
          v['diagnosis']   = argvs['reason'] || ''
          v['agent']       = self.smtpagent

          # Generate pseudo message/rfc822 part
          rfc822head = {
            'from' => Sisimai::Address.undisclosed('s'),
            'date' => v['date'],
          }
        end
        return { 'ds' => dscontents, 'rfc822' => rfc822head }
      end

    end
  end
end

