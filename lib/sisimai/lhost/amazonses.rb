module Sisimai::Lhost
  # Sisimai::Lhost::AmazonSES parses a bounce email which created by
  # Amazon Simple Email Service.
  # Methods in the module are called from only Sisimai::Message.
  module AmazonSES
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Lhost/AmazonSES.pm
      require 'sisimai/lhost'

      # https://aws.amazon.com/ses/
      Indicators = Sisimai::Lhost.INDICATORS
      StartingOf = {
        message: ['The following message to <', 'An error occurred while trying to deliver the mail'],
        rfc822:  ['content-type: message/rfc822'],
      }.freeze
      MessagesOf = { 'expired' => ['Delivery expired'] }.freeze

      def description; return 'Amazon SES(Sending): https://aws.amazon.com/ses/'; end
      def smtpagent;   return Sisimai::Lhost.smtpagent(self); end

      # X-SenderID: Sendmail Sender-ID Filter v1.0.0 nijo.example.jp p7V3i843003008
      # X-Original-To: 000001321defbd2a-788e31c8-2be1-422f-a8d4-cf7765cc9ed7-000000@email-bounces.amazonses.com
      # X-AWS-Outgoing: 199.255.192.156
      # X-SES-Outgoing: 2016.10.12-54.240.27.6
      def headerlist;  return %w[x-aws-outgoing x-ses-outgoing x-amz-sns-message-id]; end

      # Parse bounce messages from Amazon SES
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
        if mbody.start_with('{')
          # The message body is JSON string
          return nil unless mhead['x-amz-sns-message-id']
          return nil if mhead['x-amz-sns-message-id'].empty?

          hasdivided = mbody.split("\n")
          jsonstring = ''
          sespayload = nil
          foldedline = false

          while e = hasdivided.shift do
            # Find JSON string from the message body
            next if e.empty?
            break if e == '--'
            break if e == '__END_OF_EMAIL_MESSAGE__'

            # The line starts with " ", continued from !\n.
            e.lstrip! if foldedline
            foldedline = false

            if e.end_with?('!')
              # ... long long line ...![\n]
              e.chomp!('!')
              foldedline = true
            end
            jsonstring << e
          end

          begin
            if RUBY_PLATFORM.start_with?('java')
              # java-based ruby environment like JRuby.
              require 'jrjackson'
              jsonobject = JrJackson::Json.load(jsonstring)

              # 'Message' => '{"notificationType":"Bounce",...
              sespayload = JrJackson::Json.load(jsonobject['Message']) if jsonobject['Message']
            else
              # Matz' Ruby Implementation
              require 'oj'
              jsonobject = Oj.load(jsonstring)

              # 'Message' => '{"notificationType":"Bounce",...
              sespayload = Oj.load(jsonobject['Message']) if jsonobject['Message']
            end
            sespayload ||= jsonobject

          rescue StandardError => ce
            # Something wrong in decoding JSON
            warn ' ***warning: Failed to decode JSON: ' << ce.to_s
            return nil
          end

          return json(sespaylod)
        else
          # The message body is an email

          # :from    => %r/\AMAILER-DAEMON[@]email[-]bounces[.]amazonses[.]com\z/,
          # :subject => %r/\ADelivery Status Notification [(]Failure[)]\z/,
          return nil if mhead['x-mailer'].to_s.start_with?('Amazon WorkMail')

          match  = 0
          match += 1 if mhead['x-aws-outgoing']
          match += 1 if mhead['x-ses-outgoing']
          return nil unless match > 0

          require 'sisimai/rfc1894'
          fieldtable = Sisimai::RFC1894.FIELDTABLE
          permessage = {}     # (Hash) Store values of each Per-Message field

          dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
          hasdivided = mbody.split("\n")
          havepassed = ['']
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          v = nil

          while e = hasdivided.shift do
            # Save the current line for the next loop
            havepassed << e
            p = havepassed[-2]

            if readcursor == 0
              # Beginning of the bounce message or message/delivery-status part
              if e.start_with?(StartingOf[:message][0], StartingOf[:message][1])
                readcursor |= Indicators[:deliverystatus]
                next
              end
            end

            if (readcursor & Indicators[:'message-rfc822']) == 0
              # Beginning of the original message part(message/rfc822)
              if e == StartingOf[:rfc822][0]
                readcursor |= Indicators[:'message-rfc822']
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] > 0
              # message/rfc822 OR text/rfc822-headers part
              if e.empty?
                blanklines += 1
                break if blanklines > 1
                next
              end
              rfc822list << e
            else
              # message/delivery-status part
              next if (readcursor & Indicators[:deliverystatus]) == 0
              next if e.empty?

              if f = Sisimai::RFC1894.match(e)
                # "e" matched with any field defined in RFC3464
                next unless o = Sisimai::RFC1894.field(e)
                v = dscontents[-1]

                if o[-1] == 'addr'
                  # Final-Recipient: rfc822; kijitora@example.jp
                  # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                  if o[0] == 'final-recipient'
                    # Final-Recipient: rfc822; kijitora@example.jp
                    if v['recipient']
                      # There are multiple recipient addresses in the message body.
                      dscontents << Sisimai::Lhost.DELIVERYSTATUS
                      v = dscontents[-1]
                    end
                    v['recipient'] = o[2]
                    recipients += 1
                  else
                    # X-Actual-Recipient: rfc822; kijitora@example.co.jp
                    v['alias'] = o[2]
                  end
                elsif o[-1] == 'code'
                  # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                  v['spec'] = o[1]
                  v['diagnosis'] = o[2]
                else
                  # Other DSN fields defined in RFC3464
                  next unless fieldtable.key?(o[0])
                  v[fieldtable[o[0]]] = o[2]

                  next unless f == 1
                  permessage[fieldtable[o[0]]] = o[2]
                end
              else
                # Continued line of the value of Diagnostic-Code field
                next unless p.start_with?('Diagnostic-Code:')
                next unless cv = e.match(/\A[ \t]+(.+)\z/)
                v['diagnosis'] << ' ' << cv[1]
                havepassed[-1] = 'Diagnostic-Code: ' << e
              end
            end # End of message/delivery-status
          end

          if recipients == 0 && mbody =~ /notificationType/
            # Try to parse with Sisimai::Lhost::JSON::AmazonSES module
            require 'sisimai/bite/json/amazonses'
            j = Sisimai::Lhost::JSON::AmazonSES.scan(mhead, mbody)

            if j['ds'].is_a? Array
              # Update dscontents
              dscontents = j['ds']
              recipients = j['ds'].size
            end
          end
          return nil unless recipients > 0

          dscontents.each do |e|
            # Set default values if each value is empty.
            e['lhost'] ||= permessage['rhost']
            permessage.each_key { |a| e[a] ||= permessage[a] || '' }

            e['agent'] = self.smtpagent
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'].to_s.tr("\n", ' '))

            if e['status'].to_s.start_with?('5.0.0', '5.1.0', '4.0.0', '4.1.0')
              # Get other D.S.N. value from the error message
              errormessage = e['diagnosis']

              if cv = e['diagnosis'].match(/["'](\d[.]\d[.]\d.+)['"]/)
                # 5.1.0 - Unknown address error 550-'5.7.1 ...
                errormessage = cv[1]
              end
              e['status'] = Sisimai::SMTP::Status.find(errormessage) || e['status']
            end

            MessagesOf.each_key do |r|
              # Verify each regular expression of session errors
              next unless MessagesOf[r].any? { |a| e['diagnosis'].include?(a) }
              e['reason'] = r
              break
            end

          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end # END of a parser for email message
      end # END of def make()

      # @abstract Adapt Amazon SES bounce object for Sisimai::Message format
      # @param        [Hash] argvs  bounce object(JSON) retrieved from Amazon SNS
      # @return       [Hash, Nil]   Bounce data list and message/rfc822 part or
      #                             nil if it failed to parse or the
      #                             arguments are missing
      # @since v4.20.0
      # @until v4.25.5
      def json(argvs)
        return nil unless argvs.is_a? Hash
        return nil if argvs.empty?
        return nil unless argvs.key?('notificationType')

        # https://docs.aws.amazon.com/en_us/ses/latest/DeveloperGuide/notification-contents.html
        bouncetype = {
          'Permanent' => {
            'General'    => '',
            'NoEmail'    => '',
            'Suppressed' => '',
          },
          'Transient' => {
            'General'            => '',
            'MailboxFull'        => 'mailboxfull',
            'MessageTooLarge'    => 'mesgtoobig',
            'ContentRejected'    => '',
            'AttachmentRejected' => '',
          },
        }.freeze

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]
        rfc822head = {}   # (Hash) Check flags for headers in RFC822 part
        recipients = 0    # (Integer) The number of 'Final-Recipient' header
        labeltable = {
          'Bounce'    => 'bouncedRecipients',
          'Complaint' => 'complainedRecipients',
        }
        v = nil

        if %w[Bounce Complaint].index(argvs['notificationType'])
          # { "notificationType":"Bounce", "bounce": { "bounceType":"Permanent",...
          o = argvs[argvs['notificationType'].downcase].dup
          r = o[labeltable[argvs['notificationType']]] || []

          while e = r.shift do
            # 'bouncedRecipients' => [ { 'emailAddress' => 'bounce@si...' }, ... ]
            # 'complainedRecipients' => [ { 'emailAddress' => 'complaint@si...' }, ... ]
            next unless Sisimai::RFC5322.is_emailaddress(e['emailAddress'])

            v = dscontents[-1]
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            recipients += 1
            v['recipient'] = e['emailAddress']

            if argvs['notificationType'] == 'Bounce'
              # 'bouncedRecipients => [ {
              #   'emailAddress' => 'bounce@simulator.amazonses.com',
              #   'action' => 'failed',
              #   'status' => '5.1.1',
              #   'diagnosticCode' => 'smtp; 550 5.1.1 user unknown'
              # }, ... ]
              v['action'] = e['action']
              v['status'] = e['status']

              if cv = e['diagnosticCode'].match(/\A(.+?);[ ]*(.+)\z/)
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec'] = cv[1].upcase
                v['diagnosis'] = cv[2]
              else
                v['diagnosis'] = e['diagnosticCode']
              end

              # 'reportingMTA' => 'dsn; a27-23.smtp-out.us-west-2.amazonses.com',
              if cv = o['reportingMTA'].match(/\Adsn;[ ](.+)\z/) then v['lhost'] = cv[1] end

              if bouncetype.key?(o['bounceType']) &&
                 bouncetype[o['bounceType']].key?(o['bounceSubType'])
                # 'bounce' => {
                #       'bounceType' => 'Permanent',
                #       'bounceSubType' => 'General'
                # },
                v['reason'] = bouncetype[o['bounceType']][o['bounceSubType']]
              end
            else
              # 'complainedRecipients' => [ {
              #   'emailAddress' => 'complaint@simulator.amazonses.com' }, ... ],
              v['reason'] = 'feedback'
              v['feedbacktype'] = o['complaintFeedbackType'] || ''
            end

            v['date'] = o['timestamp'] || argvs['mail']['timestamp']
            v['date'].sub!(/[.]\d+Z\z/, '')
          end
        elsif argvs['notificationType'] == 'Delivery'
          # { "notificationType":"Delivery", "delivery": { ...
          o = argvs['delivery'].dup
          r = o['recipients'] || []

          while e = r.shift do
            # 'delivery' => {
            #       'timestamp' => '2016-11-23T12:01:03.512Z',
            #       'processingTimeMillis' => 3982,
            #       'reportingMTA' => 'a27-29.smtp-out.us-west-2.amazonses.com',
            #       'recipients' => [
            #           'success@simulator.amazonses.com'
            #       ],
            #       'smtpResponse' => '250 2.6.0 Message received'
            #   },
            next unless Sisimai::RFC5322.is_emailaddress(e)

            v = dscontents[-1]
            if v['recipient']
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            recipients += 1
            v['recipient'] = e
            v['lhost']     = o['reportingMTA'] || ''
            v['diagnosis'] = o['smtpResponse'] || ''
            v['status']    = Sisimai::SMTP::Status.find(v['diagnosis']) || ''
            v['replycode'] = Sisimai::SMTP::Reply.find(v['diagnosis'])  || ''
            v['reason']    = 'delivered'
            v['action']    = 'deliverable'

            v['date'] = o['timestamp'] || argvs['mail']['timestamp']
            v['date'].sub!(/[.]\d+Z\z/, '')
          end
        else
          # The value of "notificationType" is not any of "Bounce", "Complaint",
          # or "Delivery".
          return nil
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['agent'] = self.smtpagent
        end

        if argvs['mail']['headers']
          # "headersTruncated":false,
          # "headers":[ { ...
          argvs['mail']['headers'].each do |e|
            # 'headers' => [ { 'name' => 'From', 'value' => 'neko@nyaan.jp' }, ... ],
            next unless %w[From To Subject Message-ID Date].index(e['name'])
            rfc822head[e['name'].downcase] = e['value']
          end
        end

        unless rfc822head['message-id']
          # Try to get the value of "Message-Id".
          if argvs['mail']['messageId']
            # 'messageId' => '01010157e48f9b9b-891e9a0e-9c9d-4773-9bfe-608f2ef4756d-000000'
            rfc822head['message-id'] = argvs['mail']['messageId']
          end
        end
        return { 'ds' => dscontents, 'rfc822' => rfc822head }
      end

    end
  end
end

