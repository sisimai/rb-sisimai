module Sisimai
  module MTA
    # Sisimai::MTA::X2 parses a bounce email which created by Unknown MTA #2.
    # Methods in the module are called from only Sisimai::Message.
    module X2
      # Imported from p5-Sisimail/lib/Sisimai/MTA/X2.pm
      class << self
        require 'sisimai/mta'
        require 'sisimai/rfc5322'

        Re0 = {
          :from    => %r/MAILER-DAEMON[@]/,
          :subject => %r{\A(?>
             Delivery[ ]failure
            |fail(?:ure|ed)[ ]delivery
            )
          }x,
        }
        Re1 = {
          :begin  => %r/\AUnable to deliver message to the following address/,
          :rfc822 => %r/\A--- Original message follows/,
          :endof  => %r/\A__END_OF_EMAIL_MESSAGE__\z/,
        }
        Indicators = Sisimai::MTA.INDICATORS

        def description; return 'Unknown MTA #2'; end
        def smtpagent;   return Sisimai::MTA.smtpagent(self); end
        def headerlist;  return []; end
        def pattern;     return Re0; end

        # Parse bounce messages from Unknown MTA #2
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
        def scan(mhead, mbody)
          return nil unless mhead
          return nil unless mbody
          return nil unless mhead['subject'] =~ Re0[:subject]
          return nil unless mhead['from']    =~ Re0[:from]

          dscontents = [Sisimai::MTA.DELIVERYSTATUS]
          hasdivided = mbody.split("\n")
          rfc822list = []     # (Array) Each line in message/rfc822 part string
          blanklines = 0      # (Integer) The number of blank lines
          readcursor = 0      # (Integer) Points the current cursor position
          recipients = 0      # (Integer) The number of 'Final-Recipient' header
          v = nil

          hasdivided.each do |e|
            if readcursor.zero?
              # Beginning of the bounce message or delivery status part
              if e =~ Re1[:begin]
                readcursor |= Indicators[:deliverystatus]
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] == 0
              # Beginning of the original message part
              if e =~ Re1[:rfc822]
                readcursor |= Indicators[:'message-rfc822']
                next
              end
            end

            if readcursor & Indicators[:'message-rfc822'] > 0
              # After "message/rfc822"
              if e.empty?
                blanklines += 1
                break if blanklines > 2
                next
              end
              rfc822list << e

            else
              # Before "message/rfc822"
              next if readcursor & Indicators[:deliverystatus] == 0
              next if e.empty?

              # Message from example.com.
              # Unable to deliver message to the following address(es).
              #
              # <kijitora@example.com>:
              # This user doesn't have a example.com account (kijitora@example.com) [0]
              v = dscontents[-1]

              if cv = e.match(/\A[<]([^ ]+[@][^ ]+)[>]:\z/)
                # <kijitora@example.com>:
                if v['recipient']
                  # There are multiple recipient addresses in the message body.
                  dscontents << Sisimai::MTA.DELIVERYSTATUS
                  v = dscontents[-1]
                end
                v['recipient'] = cv[1]
                recipients += 1

              else
                # This user doesn't have a example.com account (kijitora@example.com) [0]
                v['diagnosis'] ||= ''
                v['diagnosis']  += ' ' + e
              end
            end
          end
          return nil if recipients.zero?
          require 'sisimai/string'

          dscontents.map do |e|
            e['agent']     = Sisimai::MTA::X2.smtpagent
            e['diagnosis'] = Sisimai::String.sweep(e['diagnosis'])
            e.each_key { |a| e[a] ||= '' }
          end

          rfc822part = Sisimai::RFC5322.weedout(rfc822list)
          return { 'ds' => dscontents, 'rfc822' => rfc822part }
        end

      end
    end
  end
end

