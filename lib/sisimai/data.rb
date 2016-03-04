module Sisimai
  # Sisimai::Data generate parsed data from Sisimai::Message object.
  class Data
    # Imported from p5-Sisimail/lib/Sisimai/Data.pm
    require 'sisimai/address'
    require 'sisimai/rfc5322'
    require 'sisimai/smtp/reply'
    require 'sisimai/smtp/status'
    require 'sisimai/string'
    require 'sisimai/reason'
    require 'sisimai/rhost'
    require 'sisimai/time'
    require 'sisimai/datetime'

    @@rwaccessors = [
      :token,           # [String] Message token/MD5 Hex digest value
      :lhost,           # [String] local host name/Local MTA
      :rhost,           # [String] Remote host name/Remote MTA
      :alias,           # [String] Alias of the recipient address
      :listid,          # [String] List-Id header of each ML
      :reason,          # [String] Bounce reason
      :action,          # [String] The value of Action: header
      :subject,         # [String] UTF-8 Subject text
      :timestamp,       # [Sisimai::Time] Date: header in the original message
      :addresser,       # [Sisimai::Address] From address
      :recipient,       # [Sisimai::Address] Recipient address which bounced
      :messageid,       # [String] Message-Id: header
      :replycode,       # [String] SMTP Reply Code
      :smtpagent,       # [String] MTA name
      :softbounce,      # [Integer] 1 = Soft bounce, 0 = Hard bounce, -1 = ?
      :smtpcommand,     # [String] The last SMTP command
      :destination,     # [String] The domain part of the "recipinet"
      :senderdomain,    # [String] The domain part of the "addresser"
      :feedbacktype,    # [String] Feedback Type
      :diagnosticcode,  # [String] Diagnostic-Code: Header
      :diagnostictype,  # [String] The 1st part of Diagnostic-Code: Header
      :deliverystatus,  # [String] Delivery Status(DSN)
      :timezoneoffset,  # [Integer] Time zone offset(seconds)
    ]
    @@rwaccessors.each { |e| attr_accessor e }

    EndOfEmail = Sisimai::String.EOM
    RetryIndex = Sisimai::Reason.retry
    RFC822Head = Sisimai::RFC5322.HEADERFIELDS(:all)
    AddrHeader = {
      addresser: RFC822Head[:addresser],
      recipient: RFC822Head[:recipient],
    }

    # Constructor of Sisimai::Data
    # @param    [Hash] argvs    Data
    # @return   [Sisimai::Data] Structured email data
    def initialize(argvs)
      thing = {}

      # Create email address object
      x0 = Sisimai::Address.parse([argvs['addresser']])
      y0 = Sisimai::Address.parse([argvs['recipient']])

      return nil unless x0.is_a? Array
      return nil unless y0.is_a? Array

      thing[:addresser] = Sisimai::Address.new(x0.shift)
      return nil unless thing[:addresser].is_a? Sisimai::Address
      return nil if thing[:addresser].void
      thing[:senderdomain] = thing[:addresser].host

      thing[:recipient] = Sisimai::Address.new(y0.shift)
      return nil unless thing[:recipient].is_a? Sisimai::Address
      return nil if thing[:recipient].void
      thing[:destination] = thing[:recipient].host
      thing[:alias] = argvs['alias'] || ''

      @addresser    = thing[:addresser]
      @senderdomain = thing[:senderdomain]
      @recipient    = thing[:recipient]
      @destination  = thing[:destination]
      @alias        = thing[:alias]

      @token = Sisimai::String.token(@addresser.address, @recipient.address, argvs['timestamp'])
      @timestamp = Sisimai::Time.parse(::Time.at(argvs['timestamp']).to_s)
      @timezoneoffset = argvs['timezoneoffset'] || '+0000'
      @lhost          = argvs['lhost']          || ''
      @rhost          = argvs['rhost']          || ''
      @reason         = argvs['reason']         || ''
      @listid         = argvs['listid']         || ''
      @subject        = argvs['subject']        || ''
      @messageid      = argvs['messageid']      || ''
      @smtpagent      = argvs['smtpagent']      || ''
      @diagnosticcode = argvs['diagnosticcode'] || ''
      @diagnostictype = argvs['diagnostictype'] || ''
      @deliverystatus = argvs['deliverystatus'] || ''
      @smtpcommand    = argvs['smtpcommand']    || ''
      @feedbacktype   = argvs['feedbacktype']   || ''
      @action         = argvs['action']         || ''
      @replycode      = argvs['replycode']      || ''
      @replycode      = Sisimai::SMTP::Reply.find(argvs['diagnosticcode']) if @replycode.empty?
      @softbounce     = argvs['softbounce']     || ''
      @softbounce     = 1 if @replycode =~ /\A4/

      if cv = @action.match(/\A(.+?) .+/)
        @action = cv[1]
      end

    end

    # Another constructor of Sisimai::Data
    # @param          [Sisimai::Message] data Data Object
    # @param          [Hash] argvs            Parser options
    # @options argvs  [Boolean] delivered     true: Including "delivered" reason
    # @return         [Array, Nil]            List of Sisimai::Data or Nil if the
    #                                         argument is not Sisimai::Message object
    def self.make(data: nil, **argvs)
      return nil unless data
      return nil unless data.is_a? Sisimai::Message

      messageobj = data
      rfc822data = messageobj.rfc822
      fieldorder = { :recipient => [], :addresser => [] }
      objectlist = []
      rxcommands = %r/\A(?:EHLO|HELO|MAIL|RCPT|DATA|QUIT)\z/
      givenorder = argvs[:order] || {}
      delivered1 = argvs[:delivered] || false

      return nil unless messageobj.ds
      return nil unless messageobj.rfc822
      require 'sisimai/smtp'

      # Decide the order of email headers: user specified or system default.
      if givenorder.is_a?(Hash) && givenorder.keys.size > 0
        # If the order of headers for searching is specified, use the order
        # for detecting an email address.
        fieldorder.each_key do |e|
          # The order should be "Array Reference".
          next unless givenorder[e]
          next unless givenorder[e].is_a? Array
          next unless givenorder[e].size > 0
          fieldorder[e].concat(givenorder[e])
        end
      end

      fieldorder.each_key do |e|
        # If the order is empty, use default order.
        if fieldorder[e].empty?
          # Load default order of each accessor.
          fieldorder[e] = AddrHeader[e]
        end
      end

      messageobj.ds.each do |e|
        # Create parameters for new() constructor.
        o = nil # Sisimai::Data Object
        r = nil # Reason text
        p = {
          'lhost'          => e['lhost']        || '',
          'rhost'          => e['rhost']        || '',
          'alias'          => e['alias']        || '',
          'action'         => e['action']       || '',
          'reason'         => e['reason']       || '',
          'replycode'      => e['replycode']    || '',
          'smtpagent'      => e['agent']        || '',
          'recipient'      => e['recipient']    || '',
          'softbounce'     => e['softbounce']   || '',
          'smtpcommand'    => e['command']      || '',
          'feedbacktype'   => e['feedbacktype'] || '',
          'diagnosticcode' => e['diagnosis']    || '',
          'diagnostictype' => e['spec']         || '',
          'deliverystatus' => e['status']       || '',
        }
        unless delivered1
          # Skip if the value of "deliverystatus" begins with "2." such as 2.1.5
          next if p['deliverystatus'] =~ /\A2[.]/
        end

        # EMAIL_ADDRESS:
        # Detect email address from message/rfc822 part
        fieldorder[:addresser].each do |f|
          # Check each header in message/rfc822 part
          h = f.downcase
          next unless rfc822data.key?(h)
          next unless rfc822data[h].size > 0
          next unless Sisimai::RFC5322.is_emailaddress(rfc822data[h])
          p['addresser'] = rfc822data[h]
          break
        end

        # Fallback: Get the sender address from the header of the bounced
        # email if the address is not set at loop above.
        p['addresser'] ||= ''
        p['addresser']   = messageobj.header['to'] if p['addresser'].empty?

        next unless p['addresser']
        next unless p['recipient']

        # TIMESTAMP:
        # Convert from a time stamp or a date string to a machine time.
        datestring = nil
        zoneoffset = 0
        datevalues = []
        if e['date'] && e['date'].size > 0
          datevalues << e['date']
        end

        # Date information did not exist in message/delivery-status part,...
        RFC822Head[:date].each do |f|
          # Get the value of Date header or other date related header.
          next unless rfc822data[f.downcase]
          datevalues << rfc822data[f.downcase]
        end

        if datevalues.size < 2
          # Set "date" getting from the value of "Date" in the bounce message
          datevalues << messageobj.header['date']
        end

        datevalues.each do |v|
          # Parse each date value in the array
          datestring = Sisimai::DateTime.parse(v)
          break if datestring
        end

        if datestring
          # Get the value of timezone offset from $datestring
          if cv = datestring.match(/\A(.+)[ ]+([-+]\d{4})\z/)
            # Wed, 26 Feb 2014 06:05:48 -0500
            datestring = cv[1]
            zoneoffset = Sisimai::DateTime.tz2second(cv[2])
            p['timezoneoffset'] = cv[2]
          end
        end

        begin
          # Convert from the date string to an object then calculate time
          # zone offset.
          t = Sisimai::Time.strptime(datestring, '%a, %d %b %Y %T')
          p['timestamp'] = (t.to_time.to_i - zoneoffset) || nil
        rescue
          warn ' ***warning: Failed to strptime ' + datestring.to_s
        end
        next unless p['timestamp']

        # OTHER_TEXT_HEADERS:
        # Remove square brackets and curly brackets from the host variable
        %w|rhost lhost|.each do |v|
          p[v] = p[v].delete('[]()')    # Remove square brackets and curly brackets from the host variable
          p[v] = p[v].sub(/\A.+=/, '')  # Remove string before "="
          p[v] = p[v].gsub(/\r\z/, '')  # Remove CR at the end of the value

          # Check space character in each value
          if p[v] =~ / /
            # Get the first element
            p[v] = p[v].split(' ', 2).shift
          end
        end

        # Subject: header of the original message
        p['subject'] = rfc822data['subject'] || ''
        p['subject'] = p['subject'].gsub(/\r\z/, '')

        # The value of "List-Id" header
        p['listid'] = rfc822data['list-id'] || ''
        if p['listid'].size > 0
          # Get the value of List-Id header
          if cv = p['listid'].match(/\A.*([<].+[>]).*\z/)
            # List name <list-id@example.org>
            p['listid'] = cv[1]
          end
          p['listid'] = p['listid'].delete('<>')
          p['listid'] = p['listid'].gsub(/\r\z/, '')
          p['listid'] = '' if p['listid'] =~ / /
        end

        # The value of "Message-Id" header
        p['messageid'] = rfc822data['message-id'] || ''
        if p['messageid'].size > 0
          # Remove angle brackets
          if cv = p['messageid'].match(/\A([^ ]+)[ ].*/)
            p['messageid'] = cv[1]
          end
          p['messageid'] = p['messageid'].delete('<>')
          p['messageid'] = p['messageid'].gsub(/\r\z/, '')
        end

        # CHECK_DELIVERY_STATUS_VALUE:
        # Cleanup the value of "Diagnostic-Code:" header
        p['diagnosticcode'] = p['diagnosticcode'].sub(/[ \t]+#{EndOfEmail}/, '')
        d = Sisimai::SMTP::Status.find(p['diagnosticcode'])
        if d =~ /\A[45][.][1-9][.][1-9]\z/
          # Use the DSN value in Diagnostic-Code:
          p['deliverystatus'] = d
        end

        # Check the value of SMTP command
        p['smtpcommand'] = '' unless p['smtpcommand'] =~ rxcommands

        o = Sisimai::Data.new(p)
        next unless o.recipient

        if o.reason.empty? || RetryIndex.index(o.reason)
          # Decide the reason of email bounce
          r = ''
          if Sisimai::Rhost.match(o.rhost)
            # Remote host dependent error
            r = Sisimai::Rhost.get(o)
          end
          r = Sisimai::Reason.get(o) if r.empty?
          r = 'undefined' if r.empty?
          o.reason = r
        end

        if o.reason != 'feedback' && o.reason != 'vacation'
          # Bounce message which reason is "feedback" or "vacation" does
          # not have the value of "deliverystatus".
          if o.softbounce.to_s.empty?
            # The value is not set yet
            %w|deliverystatus diagnosticcode|.each do |v|
              # Set the value of softbounce
              next unless p[v].size > 0
              r = Sisimai::SMTP.is_softbounce(p[v])
              if r.nil?
                o.softbounce = -1
              else
                o.softbounce = r ? 1 : 0
              end
              break if o.softbounce > -1
            end
            o.softbounce = -1 if o.softbounce.to_s.empty?
          end

          if o.deliverystatus.empty?
            # Set pseudo status code
            torp = o.softbounce == 1 ? true : false
            pdsv = Sisimai::SMTP::Status.code(o.reason, torp)

            if pdsv.size > 0
              # Set the value of "deliverystatus" and "softbounce".
              o.deliverystatus = pdsv
              if o.softbounce == -1
                # Check the value of "softbounce" again
                torp = Sisimai::SMTP.is_softbounce(pdsv)
                if torp.nil?
                  o.softbounce = -1
                else
                  o.softbounce = torp ? 1 : 0
                end
              end
            end
          end

          if o.replycode.size > 0
            # Check both of the first digit of "deliverystatus" and "replycode"
            o.replycode = '' unless o.replycode[0, 1] == o.deliverystatus[0, 1]
          end

        else
          # The value of reason is "vacation" or "feedback"
          o.softbounce = -1
          o.replycode = ''
        end
        objectlist << o
      end
      return objectlist
    end

    # Convert from object to hash reference
    # @return   [Hash] Data in Hash reference
    def damn
      data = {}
      @@rwaccessors.each do |e|
        next if e.to_s =~ /(?:addresser|recipient|timestamp)/
        data[e.to_s] = self.send(e) || ''
      end
      data['addresser'] = self.addresser.address
      data['recipient'] = self.recipient.address
      data['timestamp'] = self.timestamp.to_time.to_i
      return data
    end
    alias :to_hash :damn

    # Data dumper
    # @param    [String] type   Data format: json, yaml
    # @return   [String, Undef] Dumped data or Undef if the value of first
    #                           argument is neither "json" nor "yaml"
    def dump(type = 'json')
      return nil unless %w|json yaml|.index(type)
      referclass = sprintf('Sisimai::Data::%s', type.upcase)

      begin
        require referclass.downcase.gsub('::', '/')
      rescue
        warn '***warning: Failed to load' + referclass
      end

      dumpeddata = Module.const_get(referclass).dump(self)
      return dumpeddata
    end

    # JSON handler
    # @return   [String]            JSON string converted from Sisimai::Data
    def to_json(*)
      return self.dump('json')
    end

  end
end
