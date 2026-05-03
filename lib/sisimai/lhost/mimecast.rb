module Sisimai::Lhost
  # Sisimai::Lhost::Mimecast decodes a bounce email which created by Mimecast https://www.mimecast.com/.
  # Methods in the module are called from only Sisimai::Message.
  module Mimecast
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      Boundaries = ['Content-Type: message/rfc822'].freeze # No such line in lhost-mimecast-*
      StartingOf = {message: ['-- ']}.freeze

      # @abstract Decodes the bounce message from Mimecast
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        match  = 0
        match += 1 if mhead['subject'].include?('Email Delivery Failure')
        if mhead['message-id']
          # Message-Id: <0123456789-1102117314000@us-mta-25.us.mimecast.lan>
          match += 1 if mhead['message-id'].include?('.mimecast.lan>')
        end
        return nil if match == 0

        require 'sisimai/rfc1123'
        require 'sisimai/rfc1894'
        fieldtable = Sisimai::RFC1894.FIELDTABLE
        permessage = {}     # (Hash) Store values of each Per-Message field

        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]; v = nil
        emailparts = Sisimai::RFC5322.part(mbody, Boundaries)
        bodyslices = emailparts[0].split("\n")
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or message/delivery-status part
            readcursor |= Indicators[:deliverystatus] if e.include?(StartingOf[:message][0])
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0 || e.empty?

          v = dscontents[-1]
          if e.start_with?('-- ')
            # An email that you attempted to send to the following address could not be delivered:
            # -- sabineko@neko.ef.example.org
            cv = e[3, 256]
            if cv.include?(' ') == false
              # -- sotoneko@cat.example.com
              if v["recipient"] != ""
                # There are multiple recipient addresses in the message body.
                dscontents << Sisimai::Lhost.DELIVERYSTATUS
                v = dscontents[-1]
              end
              v['recipient'] = Sisimai::Address.s3s4(cv)
              recipients += 1
            else
              # Deal each line begins with "-- " as an error message.
              #   The problem appears to be :
              #   -- Recipient email address is possibly incorrect
              #   Additional information follows :
              #   -- 5.4.1 Recipient address rejected: Access denied. 
              v["diagnosis"] += cv + " "
            end
          else
            # Lines after Content-Type: message/delivery-status
            f = Sisimai::RFC1894.match(e)
            if f > 0
              # "e" matched with any field defined in RFC3464
              next unless o = Sisimai::RFC1894.field(e)

              if o[3] == 'code'
                # Diagnostic-Code: SMTP; 550 5.1.1 <userunknown@example.jp>... User Unknown
                v['spec'] = o[1]
                v['diagnosis'] = o[2]
              else
                # Other DSN fields defined in RFC3464
                next if fieldtable[o[0]].nil?
                next if o[3] == "host" && Sisimai::RFC1123.is_internethost(o[2]) == false
                v[fieldtable[o[0]]] = o[2]

                next if f != 1
                permessage[fieldtable[o[0]]] = o[2]
              end
            end
          end
        end
        return nil if recipients == 0

        dscontents.each do |e|
          # Set default values if each value is empty.
          permessage.each_key { |a| e[a] ||= permessage[a] || '' }
        end

        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'Mimecast'; end
    end
  end
end

