module Sisimai
  # Sisimai::Message convert bounce email text to data structure. It resolve
  # email text into an UNIX From line, the header part of the mail, delivery
  # status, and RFC822 header part. When the email given as a argument of "new"
  # method is not a bounce email, the method returns nil.
  class Message
    # Imported from p5-Sisimail/lib/Sisimai/Message.pm
    require 'sisimai/arf'
    require 'sisimai/mime'
    require 'sisimai/order'
    require 'sisimai/string'
    require 'sisimai/address'
    require 'sisimai/rfc5322'
    require 'sisimai/rfc3834'
    require 'sisimai/smtp/error'

    @@rwaccessors = [
      :from,    # [String] UNIX From line
      :header,  # [Hash]   Header part of an email
      :ds,      # [Array]  Parsed data by Sisimai::Lhost::* module
      :rfc822,  # [Hash]   Header part of the original message
      :catch,   # [Any]      The results returned by hook method
    ]
    @@rwaccessors.each { |e| attr_accessor e }

    DefaultSet = Sisimai::Order.another
    ExtHeaders = Sisimai::Order.headers
    SubjectTab = Sisimai::Order.by('subject')
    RFC822Head = Sisimai::RFC5322.HEADERFIELDS
    RFC3834Set = Sisimai::RFC3834.headerlist
    HeaderList = %w[from to date subject content-type reply-to message-id
                    received content-transfer-encoding return-path x-mailer]
    IsMultiple = { 'received' => true }
    EndOfEmail = Sisimai::String.EOM
    BorderLine = '__MIME_ENCODED_BOUNDARY__'

    # Constructor of Sisimai::Message
    # @param         [String] data      Email text data
    # @param         [Hash] argvs       Module to be loaded
    # @options argvs [String] :data     Entire email message
    # @options argvs [Array]  :load     User defined MTA module list
    # @options argvs [Array]  :field    Email header names to be captured
    # @options argvs [Array]  :order    The order of MTA modules
    # @options argvs [Code]   :hook     Reference to callback method
    # @return        [Sisimai::Message] Structured email data or nil if each
    #                                   value of the arguments are missing
    def initialize(data: '', **argvs)
      return nil if data.empty?

      email = data
      input = email.is_a?(Hash) ? 'json' : 'email'
      field = argvs[:field] || []

      if input == 'email'
        # Email message
        return nil if email.empty?
        email = email.scrub('?').gsub("\r\n", "\n")
      end

      unless field.is_a? Array
        # Unsupported value in "field"
        warn ' ***warning: "field" accepts an array reference only'
        return nil
      end

      methodargv = {
        'data'  => email,
        'hook'  => argvs[:hook] || nil,
        'field' => field,
        'input' => input,
      }
      [:load, :order].each do |e|
        # Order of MTA modules
        next unless argvs.key?(e)
        next unless argvs[e].is_a? Array
        next if argvs[e].empty?
        methodargv[e.to_s] = argvs[e]
      end

      datasource = Sisimai::Message.make(methodargv)
      return nil unless datasource
      return nil unless datasource.key?('ds')

      @from   = datasource['from']
      @header = datasource['header']
      @ds     = datasource['ds']
      @rfc822 = datasource['rfc822']
      @catch  = datasource['catch'] || nil
    end

    # Check whether the object has valid content or not
    # @return        [True,False]   returns true if the object is void
    def void
      return true unless @ds
      return false
    end

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
      tobeloaded = Sisimai::Message.load(methodargv)

      if argvs['input'] == 'email'
        # Email message
        # 1. Split email data to headers and a body part.
        return nil unless aftersplit = Sisimai::Message.divideup(email)

        # 2. Convert email headers from text to hash reference
        headerargv = {
          'extheaders' => ExtHeaders,
          'tryonfirst' => [],
          'extrafield' => argvs['field'] || [],
        }
        processing['from']   = aftersplit['from']
        processing['header'] = Sisimai::Message.headers(aftersplit['header'], headerargv)

        # 3. Check headers for detecting MTA modules
        if headerargv['tryonfirst'].empty?
          headerargv['tryonfirst'] += Sisimai::Message.makeorder(processing['header'])
        end

        # 4. Rewrite message body for detecting the bounce reason
        methodargv = {
          'hook' => hookmethod,
          'mail' => processing,
          'body' => aftersplit['body'],
          'tryonfirst' => headerargv['tryonfirst'],
          'tobeloaded' => tobeloaded,
        }
        return nil unless bouncedata = Sisimai::Message.parse(methodargv)
      else
        # JSON object
        methodargv = {
          'hook' => hookmethod,
          'json' => argvs['data'],
          'tobeloaded' => tobeloaded.concat(Sisimai::Order.forjson),
        }
        return nil unless bouncedata = Sisimai::Message.adapt(methodargv)
      end
      return nil if bouncedata.empty?

      %w|ds catch rfc822|.each { |e| processing[e] = bouncedata[e] }
      if argvs['input'] == 'email'
        # 5. Rewrite headers of the original message in the body part
        p = bouncedata['rfc822']
        p = aftersplit['body'] if p.empty?
        processing['rfc822'] = p.is_a?(::String) ? Sisimai::Message.takeapart(p) : p
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

      %w[load order].each do |e|
        # The order of MTA modules specified by user
        next unless argvs.key?(e)
        next unless argvs[e].is_a? Array
        next if argvs[e].empty?

        modulelist += argvs['order'] if e == 'order'
        next unless e == 'load'

        # Load user defined MTA module
        argvs['load'].each do |v|
          # Load user defined MTA module
          begin
            require v.to_s.gsub('::', '/').downcase
          rescue LoadError
            warn ' ***warning: Failed to load ' << v
            next
          end
          next unless argvs.input == 'email'

          Module.const_get(v).headerlist.each do |w|
            # Get header name which required user defined MTA module
            ExtHeaders[w]  ||= {}
            ExtHeaders[w][v] = 1
          end
          tobeloaded << v
        end
      end

      while e = modulelist.shift do
        # Append the custom order of MTA modules
        next if tobeloaded.index(e)
        tobeloaded << e
      end

      return tobeloaded
    end

    # Check headers for detecting MTA module and returns the order of modules
    # @param         [Hash] heads   Email header data
    # @return        [Array]        Order of MTA modules
    def self.makeorder(heads)
      return [] unless heads
      return [] unless heads['subject']
      return [] if heads['subject'].empty?
      order = []

      # Try to match the value of "Subject" with patterns generated by
      # Sisimai::Order->by('subject') method
      title = heads['subject'].downcase
      SubjectTab.each_key do |e|
        # Get MTA list from the subject header
        next unless title.include?(e)
        order += SubjectTab[e]  # Matched and push MTA list
        break
      end
      return order
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
      hasdivided = heads.split("\n")

      HeaderList.each { |e| structured[e] = nil  }
      HeaderList.each { |e| allheaders[e] = true }
      RFC3834Set.each { |e| allheaders[e] = true }
      IsMultiple.each_key { |e| structured[e] = [] }
      extheaders.each_key { |e| allheaders[e] = true }
      unless extrafield.empty?
        extrafield.each { |e| allheaders[e] = true }
      end

      while e = hasdivided.shift do
        # Convert email headers to hash
        if cv = e.match(/\A[ \t]+(.+)\z/)
          # Continued (foled) header value from the previous line
          next unless allheaders.key?(currheader)

          # Header line continued from the previous line
          if structured[currheader].is_a? Array
            # Concatenate a header which have multi-lines such as 'Received'
            structured[currheader][-1] << ' ' << cv[1]
          else
            structured[currheader] ||= ''
            structured[currheader] << ' ' << cv[1]
          end
        else
          # split the line into a header name and a header content
          (lhs, rhs) = e.split(/:[ ]*/, 2)
          currheader = lhs ? lhs.downcase : ''
          next unless allheaders.key?(currheader)

          if IsMultiple.key?(currheader)
            # Such as 'Received' header, there are multiple headers in a single
            # email message.
            #rhs = rhs.tr("\t", ' ').squeeze(' ')
            rhs = rhs.tr("\t", ' ')
            structured[currheader] << rhs
          else
            # Other headers except "Received" and so on
            if extheaders[currheader]
              # MTA specific header
              extheaders[currheader].each do |r|
                next if argvs['tryonfirst'].index(r)
                argvs['tryonfirst'] << r
              end
            end
            structured[currheader] = rhs
          end
        end
      end
      return structured
    end

    # Divide email data up headers and a body part.
    # @param         [String] email  Email data
    # @return        [Hash]          Email data after split
    def self.divideup(email)
      return nil if email.empty?

      block = { 'from' => '', 'header' => '', 'body' => '' }
      email.scrub!('?')
      email.gsub!(/\r\n/, "\n")  if email.include?("\r\n")
      email.gsub!(/[ \t]+$/, '') if email =~ /[ \t]+$/

      (block['header'], block['body']) = email.split(/\n\n/, 2)
      return nil unless block['header']
      return nil unless block['body']

      if block['header'][0, 5] == 'From '
        # From MAILER-DAEMON Tue Feb 11 00:00:00 2014
        block['from'] = block['header'].split(/\n/, 2)[0].delete("\r")
      else
        # Set pseudo UNIX From line
        block['from'] = 'MAILER-DAEMON Tue Feb 11 00:00:00 2014'
      end

      block['body'] << "\n"
      return block
    end

    # Take each email header in the original message apart
    # @param         [String] heads The original message header
    # @return        [Hash]         Structured message headers
    def self.takeapart(heads)
      return {} unless heads

      # 1. Scrub to avoid "invalid byte sequence in UTF-8" exception (#82)
      # 2. Convert from string to hash reference
      heads = heads.scrub('?').gsub(/^[>]+[ ]/m, '').gsub(/=[ ]+=/, "=\n =")

      previousfn = '' # Previous field name
      asciiarmor = {} # Header names which has MIME encoded value
      headerpart = {} # Required headers in the original message part
      hasdivided = heads.split("\n")

      while e = hasdivided.shift do
        # Header name as a key, The value of header as a value
        if e.start_with?(' ', "\t")
          # Continued (foled) header value from the previous line
          next if previousfn.empty?

          # Concatenate the line if it is the value of required header
          if Sisimai::MIME.is_mimeencoded(e)
            # The line is MIME-Encoded test
            headerpart[previousfn] << if previousfn == 'subject'
                                        # Subject: header
                                        BorderLine + e
                                      else
                                        # Is not Subject header
                                        e
                                      end
            asciiarmor[previousfn] = true
          else
            # ASCII Characters only: Not MIME-Encoded
            headerpart[previousfn] << e.lstrip
            asciiarmor[previousfn] ||= false
          end
        else
          # Header name as a key, The value of header as a value
          (lhs, rhs) = e.split(/:[ ]*/, 2)
          next unless lhs
          lhs.downcase!
          previousfn = ''

          next unless RFC822Head.key?(lhs)
          previousfn = lhs
          headerpart[previousfn] = rhs unless headerpart[previousfn]
        end
      end
      return headerpart unless headerpart['subject']

      # Convert MIME-Encoded subject
      if Sisimai::String.is_8bit(headerpart['subject'])
        # The value of ``Subject'' header is including multibyte character,
        # is not MIME-Encoded text.
        headerpart['subject'].scrub!('?')
      else
        # MIME-Encoded subject field or ASCII characters only
        r = []
        if asciiarmor['subject']
          # split the value of Subject by borderline
          headerpart['subject'].split(BorderLine).each do |v|
            # Insert value to the array if the string is MIME encoded text
            r << v if Sisimai::MIME.is_mimeencoded(v)
          end
        else
          # Subject line is not MIME encoded
          r << headerpart['subject']
        end
        headerpart['subject'] = Sisimai::MIME.mimedecode(r)
      end
      return headerpart
    end

    # @abstract Parse bounce mail with each MTA module
    # @param               [Hash] argvs    Processing message entity.
    # @param options argvs [Hash] mail     Email message entity
    # @param options mail  [String] from   From line of mbox
    # @param options mail  [Hash]   header Email header data
    # @param options mail  [String] rfc822 Original message part
    # @param options mail  [Array]  ds     Delivery status list(parsed data)
    # @param options argvs [String] body   Email message body
    # @param options argvs [Array] tryonfirst  MTA module list to load on first
    # @param options argvs [Array] tobeloaded  User defined MTA module list
    # @return              [Hash]          Parsed and structured bounce mails
    def self.parse(argvs)
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

      # Decode BASE64 Encoded message body, rewrite.
      mesgformat = (mailheader['content-type'] || '').downcase
      ctencoding = (mailheader['content-transfer-encoding'] || '').downcase

      if mesgformat.start_with?('text/plain', 'text/html')
        # Content-Type: text/plain; charset=UTF-8
        if ctencoding == 'base64'
          # Content-Transfer-Encoding: base64
          bodystring = Sisimai::MIME.base64d(bodystring)

        elsif ctencoding == 'quoted-printable'
          # Content-Transfer-Encoding: quoted-printable
          bodystring = Sisimai::MIME.qprintd(bodystring)
        end

        if mesgformat.start_with?('text/html;')
          # Content-Type: text/html;...
          bodystring = Sisimai::String.to_plain(bodystring, true)
        end
      else
        # NOT text/plain
        if mesgformat.start_with?('multipart/')
          # In case of Content-Type: multipart/*
          p = Sisimai::MIME.makeflat(mailheader['content-type'], bodystring)
          bodystring = p unless p.empty?
        end
      end

      # EXPAND_FORWARDED_MESSAGE:
      # Check whether or not the message is a bounce mail.
      # Pre-Process email body if it is a forwarded bounce message.
      # Get the original text when the subject begins from 'fwd:' or 'fw:'
      if mailheader['subject'].downcase =~ /\A[ \t]*fwd?:/
        # Delete quoted strings, quote symbols(>)
        bodystring = bodystring.gsub(/^[>]+[ ]/m, '').gsub(/^[>]$/m, '')
      elsif Sisimai::MIME.is_mimeencoded(mailheader['subject'])
        # Decode MIME-Encoded "Subject:" header
        mailheader['subject'] = Sisimai::MIME.mimedecode(mailheader['subject'].split(/[ ]/))
        mailheader['subject'].scrub!('?')
      end
      bodystring = bodystring.scrub('?').delete("\r")

      if hookmethod.is_a? Proc
        # Call the hook method
        begin
          p = {
            'datasrc' => 'email',
            'headers' => mailheader,
            'message' => bodystring,
            'bounces' => nil
          }
          havecaught = hookmethod.call(p)
        rescue StandardError => ce
          warn ' ***warning: Something is wrong in hook method :' << ce.to_s
        end
      end

      bodystring << EndOfEmail
      haveloaded = {}
      parseddata = nil

      catch :PARSER do
        while true
          # 1. Sisimai::ARF
          # 2. User-Defined Module
          # 3. MTA Module Candidates to be tried on first
          # 4. Sisimai::Lhost::*
          # 5. Sisimai::RFC3464
          # 6. Sisimai::RFC3834
          if Sisimai::ARF.is_arf(mailheader)
            # Feedback Loop message
            parseddata = Sisimai::ARF.make(mailheader, bodystring)
            throw :PARSER if parseddata
          end

          while r = argvs['tobeloaded'].shift do
            # Call user defined MTA modules
            next if haveloaded[r]
            parseddata = Module.const_get(r).make(mailheader, bodystring)
            haveloaded[r] = true
            throw :PARSER if parseddata
          end

          argvs['tryonfirst'].concat(DefaultSet)
          while r = argvs['tryonfirst'].shift do
            # Try MTA module candidates
            next if haveloaded.key?(r)
            require r.gsub('::', '/').downcase
            parseddata = Module.const_get(r).make(mailheader, bodystring)
            haveloaded[r] = true
            throw :PARSER if parseddata
          end

          # When the all of Sisimai::Lhost::* modules did not return bounce
          # data, call Sisimai::RFC3464;
          require 'sisimai/rfc3464'
          parseddata = Sisimai::RFC3464.make(mailheader, bodystring)
          break if parseddata

          # Try to parse the message as auto reply message defined in RFC3834
          require 'sisimai/rfc3834'
          parseddata = Sisimai::RFC3834.make(mailheader, bodystring)
          break if parseddata

          # as of now, we have no sample email for coding this block
          break
        end
      end

      parseddata['catch'] = havecaught if parseddata
      return parseddata
    end

    # Parse bounce object with each MTA(JSON) module
    # @param               [Hash] argvs    Processing message entity.
    # @param options argvs [Hash] json     Decoded bounce object
    # @param options argvs [Proc] hook     Hook method to be called
    # @return              [Hash]          Parsed and structured bounce mails
    def self.adapt(argvs)
      Sisimai::Message.warn(self.name, 'gone')
      bouncedata = argvs['json'] || {}
      hookmethod = argvs['hook'] || nil
      havecaught = nil
      haveloaded = {}
      parseddata = nil

      # Call the hook method
      if hookmethod.is_a? Proc
        # Execute hook method
        begin
          p = {
            'datasrc' => 'json',
            'headers' => nil,
            'message' => nil,
            'bounces' => argvs['json']
          }
          havecaught = hookmethod.call(p)
        rescue StandardError => ce
          warn ' ***warning: Something is wrong in hook method :' << ce.to_s
        end
      end

      catch :ADAPTOR do
        while true
          # 1. User-Defined Module
          # 2. MTA(JSON) Module Candidates to be tried on first
          # 3. Sisimai::Lhost::*
          #
          argvs['tobeloaded'].each do |r|
            # Call user defined MTA(JSON) modules
            next if haveloaded[r]
            begin
              require r.gsub('::', '/').downcase
            rescue LoadError => ce
              warn ' ***warning: Failed to load ' << ce.to_s
              next
            end
            parseddata = Module.const_get(r).json(bouncedata)
            haveloaded[r] = true
            throw :ADAPTOR if parseddata
          end

          break # as of now, we have no sample JSON data for coding this block
        end
      end
      return nil unless parseddata
      return nil unless parseddata['ds']

      parseddata['catch'] = havecaught
      parseddata['ds'].each { |e| e['agent'].sub!(/\AEmail::/, 'JSON::') }
      return parseddata
    end

    # @abstract Print warnings about an obsoleted method. This method will be
    #           removed at the future release of Sisimai
    # @until    v4.25.5
    def self.warn(whois = '', useit = nil)
      label = ' ***warning:'
      methodname = caller[0][/`.*'/][1..-2]
      messageset = sprintf("%s %s.%s is marked as obsoleted", label, whois, methodname)

      useit ||= methodname
      messageset << sprintf(" and will be removed at %s.", Sisimai::Lhost.removedat)
      messageset << sprintf(" Use %s.%s instead.\n", self.name, useit) if useit != 'gone'
      Kernel.warn messageset
    end

  end
end

