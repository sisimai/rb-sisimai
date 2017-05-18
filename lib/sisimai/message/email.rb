module Sisimai
  # Sisimai::Message::Email convert bounce email text to data structure. It
  # resolves an email text into an UNIX From line, the header part of the mail,
  # delivery status, and RFC822 header part. When the email given as a argument
  # of "new" method is not a bounce email, the method returns nil.
  class Message
    class Email
      # Imported from p5-Sisimail/lib/Sisimai/Message/Email.pm
      require 'sisimai/arf'
      require 'sisimai/mime'
      require 'sisimai/string'
      require 'sisimai/rfc3834'
      require 'sisimai/rfc5322'
      require 'sisimai/order/email'

      @@ToBeLoaded = []
      @@TryOnFirst = []

      EndOfEmail = Sisimai::String.EOM
      RFC822Head = Sisimai::RFC5322.HEADERFIELDS
      RFC3834Set = Sisimai::RFC3834.headerlist.map { |e| e.downcase }
      HeaderList = [
        'from', 'to', 'date', 'subject', 'content-type', 'reply-to', 'message-id',
        'received', 'content-transfer-encoding', 'return-path', 'x-mailer',
      ]
      MultiHeads = { 'received' => true }
      IgnoreList = { 'dkim-signature' => true }
      Indicators = {
        :begin => (1 << 1),
        :endof => (1 << 2),
      }
      DefaultSet = Sisimai::Order::Email.another
      SubjectTab = Sisimai::Order::Email.by('subject')
      ExtHeaders = Sisimai::Order::Email.headers
      ReEncoding = Sisimai::MIME.patterns

      # Make data structure from the email message(a body part and headers)
      # @param         [Hash] argvs   Email data
      # @options argvs [String] data  Entire email message
      # @options argvs [Array]  load  User defined MTA module list
      # @options argvs [Array]  field Email header names to be captured
      # @options argvs [Array]  order The order of MTA modules
      # @options argvs [Code]   hook  Reference to callback method
      # @return        [Hash]         Resolved data structure
      def self.make(argvs)
        email = argvs['data']

        hookmethod = argvs['hook'] || nil
        processing = {
          'from'   => '',  # From_ line
          'header' => {},  # Email header
          'rfc822' => '',  # Original message part
          'ds'     => [],  # Parsed data, Delivery Status
          'catch'  => nil, # Data parsed by callback method
        }
        methodargv = {
          'load'  => argvs['load'] || [],
          'order' => argvs['order'] || []
        }
        tobeloaded = Sisimai::Message::Email.load(methodargv)

        # 1. Split email data to headers and a body part.
        aftersplit = Sisimai::Message::Email.divideup(email)
        return nil if aftersplit.empty?

        # 2. Convert email headers from text to hash reference
        headerargv = {}
        headerargv['extheaders'] = ExtHeaders
        headerargv['tryonfirst'] = []
        headerargv['extrafield'] = argvs['field'] || []
        processing['from']   = aftersplit['from']
        processing['header'] = Sisimai::Message::Email.headers(aftersplit['header'], headerargv)

        # 3. Check headers for detecting MTA/MSP module
        if headerargv['tryonfirst'].empty?
          headerargv['tryonfirst'].concat(Sisimai::Message::Email.makeorder(processing['header']))
        end

        # 4. Rewrite message body for detecting the bounce reason
        methodargv = {
          'hook' => hookmethod,
          'mail' => processing,
          'body' => aftersplit['body'],
          'tryonfirst' => headerargv['tryonfirst'],
          'tobeloaded' => tobeloaded,
        }
        bouncedata = Sisimai::Message::Email.parse(methodargv)

        return nil unless bouncedata
        return nil if bouncedata.empty?
        processing['ds']    = bouncedata['ds']
        processing['catch'] = bouncedata['catch']

        # 5. Rewrite headers of the original message in the body part
        rfc822part = bouncedata['rfc822']
        rfc822part = aftersplit['body'] if rfc822part.empty?

        if rfc822part.is_a? ::String
          # The value returned from Sisimai::MTA::* or Sisimai::MSP::* modules
          processing['rfc822'] = Sisimai::Message::Email.takeapart(rfc822part)
        else
          # The value returned from Sisimai::CED::* modules
          processing['rfc822'] = rfc822part
        end

        return processing
      end

      # Load MTA modules which specified at 'order' and 'load' in the argument
      # @param         [Hash] argvs       Module information to be loaded
      # @options argvs [Array]  load      User defined MTA module list
      # @options argvs [Array]  order     The order of MTA modules
      # @return        [Array]            Module list
      # @since v4.20.0
      def self.load(argvs)
        modulelist = []
        tobeloaded = []

        %w|load order|.each do |e|
          # The order of MTA modules specified by user
          next unless argvs.key?(e)
          next unless argvs[e].is_a? Array
          next if argvs[e].empty?

          modulelist.concat(argvs['order']) if e == 'order'
          next unless e == 'load'

          # Load user defined MTA module
          argvs['load'].each do |v|
            # Load user defined MTA module
            begin
              require v.to_s.gsub('::', '/').downcase
            rescue LoadError
              warn ' ***warning: Failed to load ' + v
              next
            end

            Module.const_get(v).headerlist.each do |w|
              # Get header name which required user defined MTA module
              ExtHeaders[w]  ||= {}
              ExtHeaders[w][v] = 1
            end
            tobeloaded << v
          end
        end

        modulelist.each do |e|
          # Append the custom order of MTA modules
          next if tobeloaded.index(e)
          tobeloaded << e
        end

        return tobeloaded
      end

      # Divide email data up headers and a body part.
      # @param         [String] email  Email data
      # @return        [Hash]          Email data after split
      def self.divideup(email)
        return {} if email.empty?

        email = email.scrub('?')
        email = email.gsub(/\r\n/, "\n")  if email =~ /\r\n/
        email = email.gsub(/[ \t]+$/, '') if email =~ /[ \t]+$/

        hasdivided = email.split("\n")
        return {} if hasdivided.empty?

        readcursor = 0
        aftersplit = { 'from' => '', 'header' => '', 'body' => '' }
        pseudofrom = 'MAILER-DAEMON Tue Feb 11 00:00:00 2014'

        if hasdivided[0][0, 5] == 'From '
          # From MAILER-DAEMON Tue Feb 11 00:00:00 2014
          aftersplit['from'] = hasdivided.shift
          aftersplit['from'] = aftersplit['from'].delete("\n").delete("\r")
        end

        # Split email data to headers and a body part.
        hasdivided.each do |e|
          # Split email data to headers and a body part.
          if readcursor & Indicators[:endof] > 0
            # The body part of the email
            aftersplit['body'] += e + "\n"

          else
            # The boundary for splitting headers and a body part does not
            # appeare yet.
            if e.empty?
              # Blank line, it is a boundary of headers and a body part
              readcursor |= Indicators[:endof] if readcursor & Indicators[:begin] > 0

            else
              # The header part of the email
              aftersplit['header'] += e + "\n"
              readcursor |= Indicators[:begin]
            end
          end
        end
        return {} if aftersplit['header'].empty?
        return {} if aftersplit['body'].empty?

        aftersplit['from'] = pseudofrom if aftersplit['from'].empty?
        return aftersplit
      end

      # Convert email headers from text to hash reference
      # @param         [String] heads  Email header data
      # @param         [Hash]   argvs
      # @param options extheaders [Array] External header table
      # @return        [Hash]          Structured email header data
      def self.headers(heads, argvs = {})
        return nil unless heads

        currheader = ''
        allheaders = {}
        structured = {}
        extheaders = argvs['extheaders'] || []
        extrafield = argvs['extrafield'] || []

        HeaderList.each { |e| structured[e] = nil  }
        HeaderList.each { |e| allheaders[e] = true }
        RFC3834Set.each { |e| allheaders[e] = true }
        MultiHeads.each_key { |e| structured[e.downcase] = [] }
        extheaders.each_key { |e| allheaders[e] = true }
        if extrafield.size > 0
          extrafield.each { |e| allheaders[e.downcase] = true }
        end

        heads.split("\n").each do |e|
          # Convert email headers to hash
          if cv = e.match(/\A([^ ]+?)[:][ ]*(.*?)\z/)
            # split the line into a header name and a header content
            lhs = cv[1]
            rhs = cv[2]

            currheader = lhs.downcase
            next unless allheaders.key?(currheader)

            if MultiHeads.key?(currheader)
              # Such as 'Received' header, there are multiple headers in a single
              # email message.
              rhs = rhs.tr("\t", ' ')
              rhs = rhs.squeeze(' ')
              structured[currheader] << rhs

            else
              # Other headers except "Received" and so on
              if extheaders[currheader]
                # MTA specific header
                extheaders[currheader].keys.each do |r|
                  next if argvs['tryonfirst'].index(r)
                  argvs['tryonfirst'] << r
                end
              end
              structured[currheader] = rhs
            end

          elsif cv = e.match(/\A[ \t]+(.+?)\z/)
            # Ignore header?
            next if IgnoreList[currheader]

            # Header line continued from the previous line
            if structured[currheader].is_a? Array
              # Concatenate a header which have multi-lines such as 'Received'
              structured[currheader][-1] += ' ' + cv[1]

            else
              structured[currheader] ||= ''
              structured[currheader]  += ' ' + cv[1]
            end
          end
        end
        return structured
      end

      # Check headers for detecting MTA/MSP module and returns the order of modules
      # @param         [Hash] heads   Email header data
      # @return        [Array]        Order of MTA/MSP modules
      def self.makeorder(heads)
        return [] unless heads
        return [] unless heads['subject']
        return [] if heads['subject'].empty?
        order = []

        # Try to match the value of "Subject" with patterns generated by
        # Sisimai::Order->by('subject') method
        SubjectTab.each_key do |e|
          # Get MTA list from the subject header
          next unless heads['subject'] =~ e

          # Matched and push MTA list
          order.concat(SubjectTab[e])
          break
        end
        return order
      end

      # Take each email header in the original message apart
      # @param         [String] heads The original message header
      # @return        [Hash]         Structured message headers
      def self.takeapart(heads)
        return {} unless heads

        # Convert from string to hash reference
        heads = heads.gsub(/^[>]+[ ]/m, '')

        takenapart = {}
        hasdivided = heads.split("\n")
        previousfn = '' # Previous field name
        borderline = '__MIME_ENCODED_BOUNDARY__'
        mimeborder = {}

        hasdivided.each do |e|
          # Header name as a key, The value of header as a value
          if cv = e.match(/\A([-0-9A-Za-z]+?)[:][ ]*(.*)\z/)
            # Header
            lhs = cv[1].downcase
            rhs = cv[2]
            previousfn = ''

            next unless RFC822Head.key?(lhs)
            previousfn = lhs
            takenapart[previousfn] = rhs unless takenapart[previousfn]

          else
            # Continued line from the previous line
            next unless e =~ /\A[ \t]+/
            next if previousfn.empty?

            # Concatenate the line if it is the value of required header
            if Sisimai::MIME.is_mimeencoded(e)
              # The line is MIME-Encoded test
              if previousfn == 'subject'
                # Subject: header
                takenapart[previousfn] += borderline + e

              else
                # Is not Subject header
                takenapart[previousfn] += e
              end
              mimeborder[previousfn] = true

            else
              # ASCII Characters only: Not MIME-Encoded
              e = e.lstrip
              takenapart[previousfn]  += e
              mimeborder[previousfn] ||= false
            end
          end
        end

        if takenapart['subject']
          # Convert MIME-Encoded subject
          v = takenapart['subject']

          if Sisimai::String.is_8bit(v)
            # The value of ``Subject'' header is including multibyte character,
            # is not MIME-Encoded text.
            v = 'MULTIBYTE CHARACTERS HAVE BEEN REMOVED'

          else
            # MIME-Encoded subject field or ASCII characters only
            r = []
            if mimeborder['subject']
              # split the value of Subject by $borderline
              v.split(Regexp.union(borderline, ' ')).each do |m|
                # Insert value to the array if the string is MIME encoded text
                r << m if Sisimai::MIME.is_mimeencoded(m)
              end
            else
              # Subject line is not MIME encoded
              r << v
            end
            v = Sisimai::MIME.mimedecode(r)
          end
          takenapart['subject'] = v
        end
        return takenapart
      end

      # Parse bounce mail with each MTA/MSP module
      # @param               [Hash] argvs    Processing message entity.
      # @param options argvs [Hash] mail     Email message entity
      # @param options mail  [String] from   From line of mbox
      # @param options mail  [Hash]   header Email header data
      # @param options mail  [String] rfc822 Original message part
      # @param options mail  [Array]  ds     Delivery status list(parsed data)
      # @param options argvs [String] body   Email message body
      # @param options argvs [Array] tryonfirst  MTA/MSP module list to load on first
      # @param options argvs [Array] tobeloaded  User defined MTA module list
      # @return              [Hash]          Parsed and structured bounce mails
      def self.parse(argvs)
        mesgentity = argvs['mail']
        bodystring = argvs['body']
        hookmethod = argvs['hook'] || nil
        havecaught = nil
        tryonfirst = argvs['tryonfirst'] || []
        tobeloaded = argvs['tobeloaded'] || []
        mailheader = mesgentity['header']

        return nil unless argvs['mail']
        return nil unless argvs['body']

        # PRECHECK_EACH_HEADER:
        # Set empty string if the value is nil
        mailheader['from']         ||= ''
        mailheader['subject']      ||= ''
        mailheader['content-type'] ||= ''

        # Decode BASE64 Encoded message body, rewrite.
        mesgformat = (mailheader['content-type'] || '').downcase
        ctencoding = (mailheader['content-transfer-encoding'] || '').downcase

        if mesgformat =~ %r{text/(?:plain|html);?}
          # Content-Type: text/plain; charset=UTF-8
          if ctencoding == 'base64' || ctencoding == 'quoted-printable'
            # Content-Transfer-Encoding: base64
            # Content-Transfer-Encoding: quoted-printable
            if ctencoding == 'base64'
              # Content-Transfer-Encoding: base64
              bodystring = Sisimai::MIME.base64d(bodystring)

            else
              # Content-Transfer-Encoding: quoted-printable
              bodystring = Sisimai::MIME.qprintd(bodystring)
            end
          end

          if mesgformat =~ %r|text/html;?|
            # Content-Type: text/html;...
            bodystring = Sisimai::String.to_plain(bodystring, true)
          end

        else
          # NOT text/plain
          if bodystring =~ ReEncoding[:'quoted-print']
            # Content-Transfer-Encoding: quoted-printable
            bodystring = Sisimai::MIME.qprintd(bodystring, mailheader)
          end

          if bodystring =~ ReEncoding[:'7bit-encoded'] &&
             cv = bodystring.match(ReEncoding[:'some-iso2022'])
            # Content-Transfer-Encoding: 7bit
            # Content-Type: text/plain; charset=ISO-2022-JP
            unless cv[1].downcase =~ /(?:us-ascii|utf[-]?8)/
              bodystring = Sisimai::String.to_utf8(bodystring, cv[1])
            end
          end
        end

        # Call the hook method
        if hookmethod.is_a? Proc
          # Execute hook method
          begin
            p = {
              'datasrc' => 'email',
              'headers' => mailheader,
              'message' => bodystring,
              'bounces' => nil
            }
            havecaught = hookmethod.call(p)
          rescue StandardError => ce
            warn sprintf(" ***warning: Something is wrong in hook method :%s", ce.to_s)
          end
        end

        # EXPAND_FORWARDED_MESSAGE:
        # Check whether or not the message is a bounce mail.
        # Pre-Process email body if it is a forwarded bounce message.
        # Get the original text when the subject begins from 'fwd:' or 'fw:'
        if mailheader['subject'] =~ /\A[ \t]*fwd?:/i
          # Delete quoted strings, quote symbols(>)
          bodystring = bodystring.gsub(/^[>]+[ ]/m, '')
          bodystring = bodystring.gsub(/^[>]$/m, '')
        end
        bodystring += EndOfEmail
        haveloaded  = {}
        scannedset  = nil

        catch :SCANNER do
          loop do
            # 1. Sisimai::ARF
            # 2. User-Defined Module
            # 3. MTA Module Candidates to be tried on first
            # 4. Sisimai::MTA::* and MSP::*
            # 5. Sisimai::RFC3464
            # 6. Sisimai::RFC3834
            #
            if Sisimai::ARF.is_arf(mailheader)
              # Feedback Loop message
              scannedset = Sisimai::ARF.scan(mailheader, bodystring)
              throw :SCANNER if scannedset
            end

            tobeloaded.each do |r|
              # Call user defined MTA modules
              next if haveloaded[r]
              begin
                require r.gsub('::', '/').downcase
              rescue LoadError => ce
                warn ' ***warning: Failed to load ' + ce.to_s
                next
              end
              scannedset = Module.const_get(r).scan(mailheader, bodystring)
              haveloaded[r] = true
              throw :SCANNER if scannedset
            end

            tryonfirst.each do |r|
              # Try MTA module candidates which are detected from MTA specific
              # mail headers on first
              next if haveloaded.key?(r)
              begin
                require r.gsub('::', '/').downcase
              rescue LoadError => ce
                warn ' ***warning: ' + ce.to_s
                next
              end
              scannedset = Module.const_get(r).scan(mailheader, bodystring)
              haveloaded[r] = true
              throw :SCANNER if scannedset
            end

            DefaultSet.each do |r|
              # MTA/MSP modules which does not have MTA specific header and did
              # not match with any regular expressions of Subject header.
              next if haveloaded.key?(r)
              begin
                scannedset = Module.const_get(r).scan(mailheader, bodystring)
                haveloaded[r] = true
                throw :SCANNER if scannedset
              rescue => ce
                warn ' ***warning: ' + ce.to_s
                next
              end

            end

            # When the all of Sisimai::MTA::* modules did not return bounce data,
            # call Sisimai::RFC3464;
            require 'sisimai/rfc3464'
            scannedset = Sisimai::RFC3464.scan(mailheader, bodystring)
            break if scannedset

            # Try to parse the message as auto reply message defined in RFC3834
            require 'sisimai/rfc3834'
            scannedset = Sisimai::RFC3834.scan(mailheader, bodystring)
            break if scannedset

            # as of now, we have no sample email for coding this block
            break
          end
        end

        scannedset['catch'] = havecaught if scannedset
        return scannedset
      end

    end
  end
end
