module Sisimai::Lhost
  # Sisimai::Lhost::DeutscheTelekom decodes a bounce email which created by Deutsche Telekom or
  # T-Online. Methods in the module are called from only Sisimai::Message.
  module DeutscheTelekom
    class << self
      require 'sisimai/lhost'

      Indicators = Sisimai::Lhost.INDICATORS
      BannerDTAG = Sisimai::Lhost.BannerDTAG
      StartingOf = { message: [BannerDTAG[1]] }.freeze

      # @abstract Decodes the bounce message from DeutscheTelekom
      # @param  [Hash] mhead    Message headers of a bounce email
      # @param  [String] mbody  Message body of a bounce email
      # @return [Hash]          Bounce data list and message/rfc822 part
      # @return [Nil]           it failed to decode or the arguments are missing
      def inquire(mhead, mbody)
        # - T-Online: https://www.t-online.de/, @t-online.de, @magenta.de
        # - DeutscheTelekom: https://www.telekom.com/
        #   - Based on the bounce format of Smail 3, the original design model for Exim
        #   - Tailored for Deutsche Telekom's internal Smail 3 fork with custom banners
        #   - Module name follows the infrastructure owner for cross-language compatibility
        # - Smail 3: http://www.weird.com/~woods/projects/smail.html
        return nil unless BannerDTAG.any? { |a| mbody.include?(a) }

        # smail-3.2.0.108/src/
        #  notify.c:1052|(void) fprintf(f, "Subject: mail failed, %s\nReference: <%s@%s>\n\n",
        #  notify.c:1053|       subject_to, message_id, primary_name);
        # 
        # T-Online specific headers
        #   Received: from mailin42.aul.t-online.de (mailin42.aul.t-online.de [192.51.100.1])
        #     by mailout11.t-online.de (Postfix) with SMTP id 05E5A1CAC0
        #   From: Mail Delivery System <Mailer-Daemon@t-online.de>
        #   X-TOI-MSGID: c9412855-531f-497b-b007-5ffc033877a0
        dscontents = [Sisimai::Lhost.DELIVERYSTATUS]; v = nil
        emailparts = Sisimai::RFC5322.part(mbody, [BannerDTAG[3], BannerDTAG[2]])
        bodyslices = emailparts[0].split("\n")
        messagelog = ''
        readcursor = 0      # (Integer) Points the current cursor position
        recipients = 0      # (Integer) The number of 'Final-Recipient' header

        while e = bodyslices.shift do
          # Read error messages and delivery status lines from the head of the email to the previous
          # line of the beginning of the original message.
          if readcursor == 0
            # Beginning of the bounce message or delivery status part
            if e.start_with?(StartingOf[:message][0])
              # |------------------------- Failed addresses follow: ---------------------|
              readcursor |= Indicators[:deliverystatus]
            else
              # |------------------------- Message log follows: -------------------------|
              # The line above may appears only in Smail 3.
              #
              # smail-3.2.0.108/src/
              #   models.c:787| if (deliver == NULL && defer == NULL) {
              #   models.c:788| write_log(WRITE_LOG_MLOG, "no valid recipients were found for this message");
              #   models.c:789| return_to_sender = TRUE;
              #   models.c:879| }
              messagelog += ' ' + e if e != "" && e.include?(BannerDTAG[0]) == false
            end
            next
          end
          next if (readcursor & Indicators[:deliverystatus]) == 0 || e.empty?

          # |------------------------- Failed addresses follow: ---------------------|
          #  <example@t-online.de>
          #    552 5.2.2 <example@t-online.de> Quota exceeded (mailbox for user is full)
          # 
          # |------------------------- Message header follows: ----------------------|
          # Received: from mail.fragdenstaat.de ([94.130.55.89]) by mailin41.mgt.mul.t-online.de.example.com
          #  with (TLSv1.3:TLS_AES_256_GCM_SHA384 encrypted)
          # ...
          v = dscontents[-1]


          if e.start_with?(' <') && e.end_with?('>') && e.count(' ') == 1
            # Deutsche Telekom: The recipient address is enclosed in angle brackets.
            # |------------------------- Failed addresses follow: ---------------------|
            if v["recipient"] != ""
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = e[2, e.size]
            recipients += 1

          elsif Sisimai::String.aligned(e, [' ', '@', '.', ' ... '])
            # Smail 3:
            #   - The recipient address is not enclosed in angle brackets.
            #   - Error message begins with " ... failed:"
            # smail-3.2.0.108/src/
            #   notify.c:845| if (cur->error) {
            #   notify.c:846| (void) fprintf(f, " %s ... failed: %s\n",
            #   notify.c:847|            cur->in_addr ? cur->in_addr : "(unknown)",
            #   notify.c:848|            cur->error->message);
            #   notify.c:849| }
            # |------------------------- Failed addresses follow: ---------------------|
            #  kijitora@neko.nyaan.example.com ... unknown host
            if v["recipient"] != ""
              # There are multiple recipient addresses in the message body.
              dscontents << Sisimai::Lhost.DELIVERYSTATUS
              v = dscontents[-1]
            end
            v['recipient'] = e[1, e.index(' ... ')]
            v['diagnosis'] = messagelog << ' ' + e
            recipients += 1

          else
            #    552 5.2.2 <example@t-online.de> Quota exceeded (mailbox for user is full)
            v['diagnosis'] = e
          end
        end
        return nil if recipients == 0
        return { 'ds' => dscontents, 'rfc822' => emailparts[1] }
      end
      def description; return 'DeutscheTelekom'; end
    end
  end
end

