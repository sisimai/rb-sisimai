module Sisimai
  # Sisimai::Message convert bounce email text to data structure. It resolve email text into an UNIX
  # From line, the header part of the mail, delivery status, and RFC822 header part. When the email
  # given as a argument of "rise" method is not a bounce email, the method returns nil.
  module Message
    class << self
      require 'sisimai/rfc1894'
      require 'sisimai/rfc2045'
      require 'sisimai/rfc5322'
      require 'sisimai/rfc5965'
      require 'sisimai/address'
      require 'sisimai/string'
      require 'sisimai/order'
      require 'sisimai/lhost'

      DefaultSet = Sisimai::Order.another.freeze
      LhostTable = Sisimai::Lhost.path.freeze
      Fields1894 = Sisimai::RFC1894.FIELDINDEX.freeze
      Fields5322 = Sisimai::RFC5322.FIELDINDEX.freeze
      Fields5965 = Sisimai::RFC5965.FIELDINDEX.freeze
      FieldIndex = [Fields1894.flatten, Fields5322.flatten, Fields5965.flatten].flatten.freeze
      FieldTable = FieldIndex.map { |e| [e.downcase, e] }.to_h.freeze
      ReplacesAs = { 'Content-Type' => [%w[message/xdelivery-status message/delivery-status]] }.freeze
      Boundaries = ['Content-Type: message/rfc822', 'Content-Type: text/rfc822-headers'].freeze

      # Read an email message and convert to structured format
      # @param         [Hash] argvs       Module to be loaded
      # @options argvs [String] :data     Entire email message
      # @options argvs [Code]   :hook     Reference to callback method
      # @return        [Sisimai::Message] Structured email data or nil if each
      #                                   value of the arguments are missing
      def rise(**argvs)
        return nil unless argvs
        email = argvs[:data].scrub('?').gsub("\r\n", "\n")
        thing = { 'from' => '','header' => {}, 'rfc822' => '', 'ds' => [], 'catch' => nil }
        param = {}

        aftersplit = nil
        beforefact = nil
        parseagain = 0

        while parseagain < 2 do
          # 1. Split email data to headers and a body part.
          break unless aftersplit = Sisimai::Message.part(email)

          # 2. Convert email headers from text to hash reference
          thing['from']   = aftersplit[0]
          thing['header'] = Sisimai::Message.makemap(aftersplit[1])

          # 3. Decode and rewrite the "Subject:" header
          unless thing['header']['subject'].empty?
            # Decode MIME-Encoded "Subject:" header
            cv = thing['header']['subject']
            cq = Sisimai::RFC2045.is_encoded(cv) ? Sisimai::RFC2045.decodeH(cv.split(/[ ]/)) : cv
            cl = cq.downcase
            p1 = cl.index('fwd:'); p1 = cl.index('fw:') unless p1

            # Remove "Fwd:" string from the Subject: header
            if p1
              # Delete quoted strings, quote symbols(>)
              cq = Sisimai::String.sweep(cq[cq.index(':') + 1, cq.size])
              aftersplit[2] = aftersplit[2].gsub(/^[>]+[ ]/, '').gsub(/^[>]$/, '')
            end
            thing['header']['subject'] = cq
          end

          # 4. Rewrite message body for detecting the bounce reason
          param = {
            'hook' => argvs[:hook] || nil,
            'mail' => thing,
            'body' => aftersplit[2],
            'tryonfirst' => Sisimai::Order.make(thing['header']['subject'])
          }
          break if beforefact = Sisimai::Message.sift(param)
          break unless Boundaries.any? { |a| aftersplit[2].include?(a) }

          # 5. Try to sift again
          #    There is a bounce message inside of mutipart/*, try to sift the first message/rfc822
          #    part as a entire message body again.
          parseagain += 1
          email = Sisimai::RFC5322.part(aftersplit[2], Boundaries, true).pop.sub(/\A[\r\n\s]+/, '')
          break unless email.size > 128
        end
        return nil unless beforefact
        return nil if beforefact.empty?

        # 6. Rewrite headers of the original message in the body part
        %w|ds catch rfc822|.each { |e| thing[e] = beforefact[e] }
        p = beforefact['rfc822']
        p = aftersplit[2] if p.empty?
        thing['rfc822'] = p.is_a?(::String) ? Sisimai::Message.makemap(p, true) : p

        return thing
      end

      def load(argvs); ' ***warning: Sisimai::Message->load will be removed at v5.1.1'; return []; end

      # Divide email data up headers and a body part.
      # @param         [String] email  Email data
      # @return        [Array]         Email data after split
      def part(email)
        return nil if email.empty?

        parts = ['', '', '']  # 0:From, 1:Header, 2:Body
        email.gsub!(/\A\s+/, '')
        email.gsub!(/\r\n/, "\n") if email.include?("\r\n")

        (parts[1], parts[2]) = email.split(/\n\n/, 2)
        return nil unless parts[1]
        return nil unless parts[2]

        if parts[1].start_with?('From ')
          # From MAILER-DAEMON Tue Feb 11 00:00:00 2014
          parts[0] = parts[1].split(/\n/, 2)[0].delete("\r")
        else
          # Set pseudo UNIX From line
          parts[0] = 'MAILER-DAEMON Tue Feb 11 00:00:00 2014'
        end
        parts[1] << "\n" unless parts[1].end_with?("\n")

        %w[image/ application/ text/html].each do |e|
          # https://github.com/sisimai/p5-sisimai/issues/492, Reduce email size
          p0 = 0
          p1 = 0
          ep = e == 'text/html' ? '</html>' : "--\n"
          while true
            # Remove each part from "Content-Type: image/..." to "--\n" (the end of each boundary)
            p0 = parts[2].index('Content-Type: ' + e, p0); break unless p0
            p1 = parts[2].index(ep, p0 + 32);              break unless p1
            parts[2][p0, p1 - p0] = ''
          end
        end
        parts[2] << "\n"
        return parts
      end

      # Convert a text including email headers to a hash reference
      # @param    [String] argv0  Email header data
      # @param    [Bool]   argv1  Decode "Subject:" header
      # @return   [Hash]          Structured email header data
      # @since    v4.25.6
      def makemap(argv0 = '', argv1 = nil)
        return {} if argv0.empty?
        argv0.gsub!(/^[>]+[ ]/m, '') # Remove '>' indent symbol of forwarded message

        # Select and convert all the headers in $argv0. The following regular expression is based on
        # https://gist.github.com/xtetsuji/b080e1f5551d17242f6415aba8a00239
        headermaps = { 'subject' => '' }
        receivedby = []
        argv0.scan(/^([\w-]+):[ ]*(.*?)\n(?![\s\t])/m) { |e| headermaps[e[0].downcase] = e[1] }
        headermaps.delete('received')
        headermaps.each_key { |e| headermaps[e].gsub!(/\n[\s\t]+/, ' ') }

        if argv0.include?('Received:')
          # Capture values of each Received: header
          re = argv0.scan(/^Received:[ ]*(.*?)\n(?![\s\t])/m).flatten
          re.each do |e|
            # 1. Exclude the Received header including "(qmail ** invoked from network)".
            # 2. Convert all consecutive spaces and line breaks into a single space character.
            next if e.include?(' invoked by uid')
            next if e.include?(' invoked from network')

            e.gsub!(/\n[\s\t]+/, ' ')
            e.squeeze!("\n\t ")
            receivedby << e
          end
        end
        headermaps['received'] = receivedby

        return headermaps unless argv1
        return headermaps if headermaps['subject'].empty?

        # Convert MIME-Encoded subject
        if Sisimai::String.is_8bit(headermaps['subject'])
          # The value of ``Subject'' header is including multibyte character, is not MIME-Encoded text.
          headermaps['subject'].scrub!('?')
        else
          # MIME-Encoded subject field or ASCII characters only
          r = []
          if Sisimai::RFC2045.is_encoded(headermaps['subject'])
            # split the value of Subject by borderline
            headermaps['subject'].split(/ /).each do |v|
              # Insert value to the array if the string is MIME encoded text
              r << v if Sisimai::RFC2045.is_encoded(v)
            end
          else
            # Subject line is not MIME encoded
            r << headermaps['subject']
          end
          headermaps['subject'] = Sisimai::RFC2045.decodeH(r)
        end
        return headermaps
      end

      # @abstract Tidy up each field name and format
      # @param    [String] argv0 Strings including field and value used at an email
      # @return   [String]       Strings tidied up
      # @since v5.0.0
      def tidy(argv0 = '')
        return '' if argv0.empty?

        email = ''
        lines = argv0.split("\n")
        index = -1
        lines.each do |e|
          # Find and tidy up fields defined in RFC5322, RFC1894, and RFC5965
          # 1. Find a field label defined in RFC5322, RFC1894, or RFC5965 from this line
          p0 = e.index(':') || -1
          cf = e.downcase[0, p0]
          fn = FieldTable[cf] || ''

          index += 1
          if fn == ''
            # There is neither ":" character nor the field listed in $FieldTable
            email << e + "\n"
            next
          end

          # 2. Tidy up a sub type of each field defined in RFC1894 such as Reporting-MTA: DNS;...
          ab = []
          bf = e[p0 + 1, e.size - p0 - 1]
          p1 = bf.index(';')
          while true
            # Such as Diagnostic-Code, Remote-MTA, and so on
            # - Before: Diagnostic-Code: SMTP;550 User unknown
            # - After:  Diagnostic-Code: smtp; 550 User unknown
            break unless ['Content-Type'].concat(Fields1894).any? { |a| a == fn }

            if p1
              # The field including one or more ";"
              bf.split(';').each do |f|
                # 2-1. Trim leading and trailing space characters from the current buffer
                f.strip!
                ps = ''

                # 2-2. Convert some parameters to the lower-cased string
                while true
                  # For example,
                  # - Content-Type: Message/delivery-status => message/delivery-status
                  # - Content-Type: Charset=UTF8            => charset=utf8
                  # - Reporting-MTA: DNS; ...               => dns
                  # - Final-Recipient: RFC822; ...          => rfc822
                  break if f.include?(' ')

                  p2 = f.index('=')
                  if p2
                    # charset=, boundary=, and other pairs divided by "="
                    ps = f[0, p2].downcase
                    f[0, p2] = ps
                  end
                  f.downcase! unless ps == 'boundary'
                  break
                end
                ab << f
              end

              while true
                # Diagnostic-Code: x-unix;
                #   /var/email/kijitora/Maildir/tmp/1000000000.A000000B00000.neko22:
                #   Disk quota exceeded
                break unless fn == 'Diagnostic-Code'
                break unless ab.size == 1
                break unless lines[index + 1].start_with?(' ')

                ab << ''
                break
              end
              bf = ab.join('; ') # Insert " " (space characer) immediately after ";"
              ab = []

            else
              # There is no ";" in the field
              break if fn.end_with?('-Date')        # Arrival-Date, Last-Attempt-Date
              break if fn.end_with?('-Message-ID')  # X-Original-Message-ID
              bf.downcase!
            end
            break
          end

          # 3. Tidy up a value, and a parameter of Content-Type: field
          if ReplacesAs.has_key?(fn)
            # Replace the value of "Content-Type" field
            ReplacesAs[fn].each do |f|
              # - Before: Content-Type: message/xdelivery-status; ...
              # - After:  Content-Type: message/delivery-status; ...
              p1 = bf.index(f[0]) || next
              bf[p1, f[0].size] = f[1]
            end
          end

          # 4. Remove redundant space characters
          bf = bf.squeeze(' ').strip
          email << sprintf("%s: %s\n", fn, bf)
        end

        email << "\n" unless email.end_with?("\n\n")
        return email
      end

      # @abstract Sift bounce mail with each MTA module
      # @param               [Hash] argvs    Processing message entity.
      # @param options argvs [Hash] mail     Email message entity
      # @param options mail  [String] from   From line of mbox
      # @param options mail  [Hash]   header Email header data
      # @param options mail  [String] rfc822 Original message part
      # @param options mail  [Array]  ds     Delivery status list(decoded data)
      # @param options argvs [String] body   Email message body
      # @param options argvs [Array] tryonfirst  MTA module list to load on first
      # @return              [Hash]          Decoded and structured bounce mails
      def sift(argvs)
        return nil unless argvs['mail']
        return nil unless argvs['body']

        mailheader = argvs['mail']['header']
        bodystring = argvs['body']
        hookmethod = argvs['hook'] || nil
        havecaught = nil
        return nil unless mailheader

        # PRECHECK_EACH_HEADER:
        # Set empty string if the value is nil
        mailheader['from']         ||= ''
        mailheader['subject']      ||= ''
        mailheader['content-type'] ||= ''

        # Tidy up each field name and value in the entire message body
        bodystring = Sisimai::Message.tidy(bodystring)

        # Decode BASE64 Encoded message body, rewrite.
        mesgformat = (mailheader['content-type'] || '').downcase
        ctencoding = (mailheader['content-transfer-encoding'] || '').downcase
        if mesgformat.start_with?('text/plain', 'text/html')
          # Content-Type: text/plain; charset=UTF-8
          if ctencoding == 'base64'
            # Content-Transfer-Encoding: base64
            bodystring = Sisimai::RFC2045.decodeB(bodystring)

          elsif ctencoding == 'quoted-printable'
            # Content-Transfer-Encoding: quoted-printable
            bodystring = Sisimai::RFC2045.decodeQ(bodystring)
          end

          if mesgformat.start_with?('text/html;')
            # Content-Type: text/html;...
            bodystring = Sisimai::String.to_plain(bodystring, true)
          end
        elsif mesgformat.start_with?('multipart/')
          # NOT text/plain
          # In case of Content-Type: multipart/*
          p = Sisimai::RFC2045.makeflat(mailheader['content-type'], bodystring)
          bodystring = p unless p.empty?
        end
        bodystring = bodystring.scrub('?').delete("\r").gsub("\t", " ")

        haveloaded = {}
        havesifted = nil
        modulename = ''
        if hookmethod.is_a? Proc
          # Call the hook method
          begin
            p = { 'headers' => mailheader, 'message' => bodystring }
            havecaught = hookmethod.call(p)
          rescue StandardError => ce
            warn ' ***warning: Something is wrong in hook method ":hook":' << ce.to_s
          end
        end

        catch :DECODER do
          while true
            # 1. MTA Module Candidates to be tried on first
            # 2. Sisimai::Lhost::*
            # 3. Sisimai::RFC3464
            # 4. Sisimai::ARF
            # 5. Sisimai::RFC3834
            [argvs['tryonfirst'], DefaultSet].flatten.each do |r|
              # Try MTA module candidates
              next if haveloaded[r]
              require LhostTable[r]
              havesifted = Module.const_get(r).inquire(mailheader, bodystring)
              haveloaded[r] = true
              modulename = r
              throw :DECODER if havesifted
            end

            unless haveloaded['Sisimai::RFC3464']
              # When the all of Sisimai::Lhost::* modules did not return bounce data, call Sisimai::RFC3464;
              require 'sisimai/rfc3464'
              havesifted = Sisimai::RFC3464.inquire(mailheader, bodystring)
              modulename = 'RFC3464'
              throw :DECODER if havesifted
            end

            unless haveloaded['Sisimai::ARF']
              # Feedback Loop message
              require 'sisimai/arf'
              havesifted = Sisimai::ARF.inquire(mailheader, bodystring)
              throw :DECODER if havesifted
            end

            unless haveloaded['Sisimai::RFC3834']
              # Try to sift the message as auto reply message defined in RFC3834
              require 'sisimai/rfc3834'
              havesifted = Sisimai::RFC3834.inquire(mailheader, bodystring)
              modulename = 'RFC3834'
              throw :DECODER if havesifted
            end

            break # as of now, we have no sample email for coding this block
          end
        end
        return nil unless havesifted

        havesifted['catch'] = havecaught
        modulename = modulename.sub(/\A.+::/, '')
        havesifted['ds'].each do |e|
          e['agent'] = modulename unless e['agent']
          e.each_key { |a| e[a] ||= '' }  # Replace nil with ""
        end
        return havesifted
      end

    end
  end
end

