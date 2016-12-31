module Sisimai
  module CED::US
    # Sisimai::CED::US::AmazonSES parses a bounce object(JSON) which created by
    # Amazon Simple Email Service.
    # Methods in the module are called from only Sisimai::Message.
    module AmazonSES
      # Imported from p5-Sisimail/lib/Sisimai/CED/US/AmazonSES.pm
      class << self
        require 'sisimai/ced'
        require 'sisimai/rfc5322'

        # http://aws.amazon.com/ses/
        Re0 = {
          :from    => %r/\A[<]?no-reply[@]sns[.]amazonaws[.]com[>]?/,
          :subject => %r/\AAWS Notification Message\z/,
        }

        # https://docs.aws.amazon.com/en_us/ses/latest/DeveloperGuide/notification-contents.html
        BounceType = {
          :Permanent => {
            :General    => '',
            :NoEmail    => '',
            :Suppressed => '',
          },
          :Transient => {
            :General            => '',
            :MailboxFull        => 'mailboxfull',
            :MessageTooLarge    => 'mesgtoobig',
            :ContentRejected    => '',
            :AttachmentRejected => '',
          },
        }
        Indicators = Sisimai::CED.INDICATORS

        # x-amz-sns-message-id: 02f86d9b-eecf-573d-b47d-3d1850750c30
        # x-amz-sns-subscription-arn: arn:aws:sns:us-west-2:000000000000:SESEJB:ffffffff-2222-2222-2222-eeeeeeeeeeee
        def headerlist;  return ['x-amz-sns-message-id']; end
        def pattern;     return Re0; end
        def smtpagent;   return Sisimai::CED.smtpagent(self); end
        def description; return 'Amazon SES(JSON): http://aws.amazon.com/ses/'; end

        # Parse bounce messages from Amazon SES(JSON)
        # @param         [Hash] mhead       Message header of a bounce email
        # @options mhead [String] from      From header
        # @options mhead [String] date      Date header
        # @options mhead [String] subject   Subject header
        # @options mhead [Array]  received  Received headers
        # @options mhead [String] others    Other required headers
        # @param         [String] mbody     Message body of a bounce email
        # @return        [Hash, Nil]        Bounce data list and message/rfc822
        #                                   part or nil if it failed to parse or
        #                                   the arguments are missing
        # @since v4.20.0
        def scan(mhead, mbody)
          return nil unless mhead
          return nil unless mbody
          return nil unless mhead['x-amz-sns-message-id']
          return nil unless mhead['x-amz-sns-message-id'].size > 0

          hasdivided = mbody.split("\n")
          jsonstring = ''
          jsonthings = nil
          foldedline = false

          hasdivided.each do |e|
            # Find JSON string from the message body
            next if e.size == 0
            break if e =~ /\A[-]{2}\z/
            break if e == '__END_OF_EMAIL_MESSAGE__'

            # The line starts with " ", continued from !\n.
            e = e.sub(/\A[ ]/, '') if foldedline
            foldedline = false

            if e =~ /[!]\z/
              # ... long long line ...![\n]
              e = e.sub(/!\z/, '')
              foldedline = true
            end
            jsonstring += e
          end

          begin
            if RUBY_PLATFORM =~ /java/
              # java-based ruby environment like JRuby.
              require 'jrjackson'
              jsonobject = JrJackson::Json.load(jsonstring)
              if jsonobject['Message']
                # 'Message' => '{"notificationType":"Bounce",...
                jsonthings = JrJackson::Json.load(jsonobject['Message'])
              end
            else
              # Matz' Ruby Implementation
              require 'oj'
              jsonobject = Oj.load(jsonstring)
              if jsonobject['Message']
                # 'Message' => '{"notificationType":"Bounce",...
                jsonthings = Oj.load(jsonobject['Message'])
              end
            end
            jsonthings ||= jsonobject

          rescue StandardError => ce
            # Something wrong in decoding JSON
            warn sprintf(' ***warning: Failed to decode JSON: %s', ce.to_s)
            return nil
          end

          return adapt(jsonthings)
        end

        # @abstract Adapt Amazon SES bounce object for Sisimai::Message format
        # @param        [Hash] argvs  bounce object(JSON) retrieved from Amazon SNS
        # @return       [Hash, Nil]   Bounce data list and message/rfc822 part
        #                             or Undef if it failed to parse or the
        #                             arguments are missing
        # @since v4.20.0
        def adapt(argvs)
          return nil unless argvs.is_a? Hash
          return nil unless argvs.keys.size > 0
          return nil unless argvs.key?('notificationType')

          require 'sisimai/rfc5322'
          dscontents = [Sisimai::CED.DELIVERYSTATUS];
          rfc822head = {}   # (Hash) Check flags for headers in RFC822 part
          recipients = 0    # (Integer) The number of 'Final-Recipient' header
          labeltable = {
              :Bounce    => 'bouncedRecipients',
              :Complaint => 'complainedRecipients',
          }
          v = nil

          if argvs['notificationType'] =~ /\A(?:Bounce|Complaint)\z/
            # { "notificationType":"Bounce", "bounce": { "bounceType":"Permanent",...
            o = argvs[ argvs['notificationType'].downcase ]
            r = o[ labeltable[ argvs['notificationType'].to_sym ] ] || []

            r.each do |e|
              # 'bouncedRecipients' => [ { 'emailAddress' => 'bounce@si...' }, ... ]
              # 'complainedRecipients' => [ { 'emailAddress' => 'complaint@si...' }, ... ]
              next unless Sisimai::RFC5322.is_emailaddress(e['emailAddress'])

              v = dscontents[-1]
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::CED.DELIVERYSTATUS
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

                if cv = o['reportingMTA'].match(/\Adsn;[ ](.+)\z/)
                  # 'reportingMTA' => 'dsn; a27-23.smtp-out.us-west-2.amazonses.com',
                  v['lhost'] = cv[1]
                end

                if BounceType.key?(o['bounceType'].to_sym) &&
                   BounceType[o['bounceType'].to_sym].key?(o['bounceSubType'].to_sym)
                    # 'bounce' => {
                    #       'bounceType' => 'Permanent',
                    #       'bounceSubType' => 'General'
                    # },
                    v['reason'] = BounceType[o['bounceType'].to_sym][o['bounceSubType'].to_sym]
                end

              else
                # 'complainedRecipients' => [ {
                #   'emailAddress' => 'complaint@simulator.amazonses.com' }, ... ],
                v['reason'] = 'feedback'
                v['feedbacktype'] = o['complaintFeedbackType'] || ''
              end

              v['date'] = o['timestamp'] || argvs['mail']['timestamp']
              v['date'] = v['date'].sub(/[.]\d+Z\z/, '')
            end

          elsif argvs['notificationType'] == 'Delivery'
            # { "notificationType":"Delivery", "delivery": { ...
            require 'sisimai/smtp/status'
            require 'sisimai/smtp/reply'

            o = argvs['delivery']
            r = o['recipients'] || []

            r.each do |e|
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
                dscontents << Sisimai::CED.DELIVERYSTATUS
                v = dscontents[-1]
              end
              recipients += 1
              v['recipient'] = e
              v['lhost']     = o['reportingMTA'] || ''
              v['diagnosis'] = o['smtpResponse'] || ''
              v['status']    = Sisimai::SMTP::Status.find(v['diagnosis'])
              v['replycode'] = Sisimai::SMTP::Reply.find(v['diagnosis'])
              v['reason']    = 'delivered'
              v['action']    = 'deliverable'

              v['date'] = o['timestamp'] || argvs['mail']['timestamp']
              v['date'] = v['date'].sub(/[.]\d+Z\z/, '')
            end

          else
            # The value of "notificationType" is not any of "Bounce", "Complaint",
            # or "Delivery".
            return nil
          end
          return nil if recipients == 0

          dscontents.each do |e|
            e['agent'] = Sisimai::CED::US::AmazonSES.smtpagent
          end

          if argvs['mail']['headers']
            # "headersTruncated":false,
            # "headers":[ { ...
            argvs['mail']['headers'].each do |e|
              # 'headers' => [ { 'name' => 'From', 'value' => 'neko@nyaan.jp' }, ... ],
              next unless e['name'] =~ /\A(?:From|To|Subject|Message-ID|Date)\z/
              rfc822head[ e['name'].downcase ] = e['value']
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
end

