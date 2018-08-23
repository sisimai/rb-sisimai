module Sisimai::Bite::Email
  # Sisimai::Bite::Email::FML parses a bounce email which created by fml.
  # Methods in the module are called from only Sisimai::Message.
  module FML
    class << self
      # Imported from p5-Sisimail/lib/Sisimai/Bite/Email/FML.pm
      require 'sisimai/bite/email'

      Indicators = Sisimai::Bite::Email.INDICATORS
      StartingOf = { rfc822: ['Original mail as follows:'] }.freeze
      ErrorTitle = {
        :rejected => %r{(?>
           (?:Ignored[ ])*NOT[ ]MEMBER[ ]article[ ]from[ ]
          |reject[ ]mail[ ](?:.+:|from)[ ],
          |Spam[ ]mail[ ]from[ ]a[ ]spammer[ ]is[ ]rejected
          |You[ ].+[ ]are[ ]not[ ]member
          )
        }x,
        :systemerror => %r{(?:
           fml[ ]system[ ]error[ ]message
          |Loop[ ]Alert:[ ]
          |Loop[ ]Back[ ]Warning:[ ]
          |WARNING:[ ]UNIX[ ]FROM[ ]Loop
          )
        }x,
        :securityerror => %r/Security Alert/,
      }.freeze
      ErrorTable = {
        :rejected => %r{(?>
          (?:Ignored[ ])*NOT[ ]MEMBER[ ]article[ ]from[ ]
          |reject[ ](?:
             mail[ ]from[ ].+[@].+
            |since[ ].+[ ]header[ ]may[ ]cause[ ]mail[ ]loop
            |spammers:
            )
          |You[ ]are[ ]not[ ]a[ ]member[ ]of[ ]this[ ]mailing[ ]list
          )
        }x,
        :systemerror => %r{(?:
           Duplicated[ ]Message-ID
          |fml[ ].+[ ]has[ ]detected[ ]a[ ]loop[ ]condition[ ]so[ ]that
          |Loop[ ]Back[ ]Warning:
          )
        }x,
        :securityerror => %r/Security alert:/,
      }.freeze

      def description; return 'fml mailing list server/manager'; end
      def smtpagent;   return Sisimai::Bite.smtpagent(self); end
      def headerlist;  return ['X-MLServer']; end

      # Parse bounce messages from fml mailling list server/manager
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
      def scan(mhead, mbody)
        return nil unless mhead['x-mlserver']
        return nil unless mhead['from'] =~ /.+[-]admin[@].+/
        return nil unless mhead['message-id'] =~ /\A[<]\d+[.]FML.+[@].+[>]\z/

        dscontents = [Sisimai::Bite.DELIVERYSTATUS]
        hasdivided = mbody.split("\n")
        rfc822list = []     # (Array) Each line in message/rfc822 part string
        blanklines = 0      # (Integer) The number of blank lines
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header
        v = nil

        readcursor |= Indicators[:deliverystatus]
        while e = hasdivided.shift do
          if (readcursor & Indicators[:'message-rfc822']) == 0
            # Beginning of the original message part
            if e == StartingOf[:rfc822][0]
              readcursor |= Indicators[:'message-rfc822']
              next
            end
          end

          if readcursor & Indicators[:'message-rfc822'] > 0
            # After "Original mail as follows:" line
            #
            #    From owner-2ndml@example.com  Mon Nov 20 18:10:11 2017
            #    Return-Path: <owner-2ndml@example.com>
            #    ...
            #
            if e.empty?
              blanklines += 1
              break if blanklines > 1
              next
            end
            rfc822list << e.lstrip
          else
            # Before "message/rfc822"
            next if (readcursor & Indicators[:deliverystatus]) == 0
            next if e.empty?

            # Duplicated Message-ID in <2ndml@example.com>.
            # Original mail as follows:
            v = dscontents[-1]

            if cv = e.match(/[<]([^ ]+?[@][^ ]+?)[>][.]\z/)
              # Duplicated Message-ID in <2ndml@example.com>.
              if v['recipient']
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Bite.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = cv[1]
              v['diagnosis'] = e
              recipients += 1
            else
              # If you know the general guide of this list, please send mail with
              # the mail body 
              v['diagnosis'] ||= ''
              v['diagnosis'] << e
            end
          end
        end
        return nil unless recipients > 0

        dscontents.each do |e|
          e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
          e['agent']     = self.smtpagent
          e.each_key { |a| e[a] ||= '' }

          ErrorTable.each_key do |f|
            # Try to match with error messages defined in ErrorTable
            next unless e['diagnosis'] =~ ErrorTable[f]
            e['reason'] = f.to_s
            break
          end

          unless e['reason']
            # Error messages in the message body did not matched
            ErrorTitle.each_key do |f|
              # Try to match with the Subject string
              next unless mhead['subject'] =~ ErrorTitle[f]
              e['reason'] = f.to_s
              break
            end
          end
        end

        rfc822part = Sisimai::RFC5322.weedout(rfc822list)
        return { 'ds' => dscontents, 'rfc822' => rfc822part }
      end

    end
  end
end

